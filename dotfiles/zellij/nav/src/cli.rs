use crate::{feature, outbound};
use std::path::Path;
use std::process::ExitCode;

pub fn run(raw_args: Vec<String>) -> ExitCode {
    if let Some(result) = ScriptAlias::parse(&raw_args).map(|alias| alias.execute(&raw_args)) {
        return exit(result);
    }

    let result = CliCommand::parse(raw_args).and_then(|command| command.execute());
    exit(result)
}

enum CliCommand {
    Toggle,
    ContextToggleRun,
    Navigate {
        target_json: String,
    },
    RecordCurrent {
        reason: String,
    },
    Repo,
    RepoTo {
        repo: String,
    },
    Diagnose,
    PickerCandidates {
        mode: String,
    },
    PickerTarget {
        selection: String,
    },
    PickerCommand {
        command_id: String,
    },
    PickerPreview(PickerPreviewArgs),
    PickerRun {
        mode: String,
        preview_program: String,
    },
    HelperFocusUnderlying,
    HelperClose {
        session: String,
        pane_id: String,
    },
    PluginSwitch(SwitchArgs),
    SidecarPlan(SwitchArgs),
    SidecarPrepare(SwitchArgs),
    SidecarWaitAttached {
        session: String,
        previous_count: u32,
    },
    SidecarRun(SwitchArgs),
}

struct PickerPreviewArgs {
    kind: String,
    session: String,
    tab_id: String,
    pane_id: String,
    command_id: String,
    label: String,
}

struct SwitchArgs {
    session: String,
    kind: String,
    tab_id: String,
    pane_id: String,
}

enum ScriptAlias {
    PanePicker,
    ContextToggle,
    DiagnoseContext,
    PluginSwitch,
    Sidecar,
}

impl CliCommand {
    fn parse(raw_args: Vec<String>) -> Result<Self, String> {
        let mut args = raw_args.into_iter().skip(1);
        let command = args.next();

        match command.as_deref() {
            Some("navigate") => Ok(Self::Navigate {
                target_json: args.next().unwrap_or_default(),
            }),
            Some("record-current") => Ok(Self::RecordCurrent {
                reason: args.next().unwrap_or_else(|| "external".to_string()),
            }),
            Some("repo") => match args.next() {
                Some(repo) => Ok(Self::RepoTo { repo }),
                None => Ok(Self::Repo),
            },
            Some("repo-to") => Ok(Self::RepoTo {
                repo: args.next().unwrap_or_default(),
            }),
            Some("toggle") => Ok(Self::Toggle),
            Some("context-toggle-run") => Ok(Self::ContextToggleRun),
            Some("diagnose") => Ok(Self::Diagnose),
            Some("picker-candidates") => Ok(Self::PickerCandidates {
                mode: args.next().unwrap_or_else(|| "--all".to_string()),
            }),
            Some("picker-target") => Ok(Self::PickerTarget {
                selection: args.next().unwrap_or_default(),
            }),
            Some("picker-command") => Ok(Self::PickerCommand {
                command_id: args.next().unwrap_or_default(),
            }),
            Some("picker-preview") => Ok(Self::PickerPreview(PickerPreviewArgs {
                kind: args.next().unwrap_or_default(),
                session: args.next().unwrap_or_default(),
                tab_id: args.next().unwrap_or_default(),
                pane_id: args.next().unwrap_or_default(),
                command_id: args.next().unwrap_or_default(),
                label: args.next().unwrap_or_default(),
            })),
            Some("picker-run") => Ok(Self::PickerRun {
                mode: args.next().unwrap_or_else(|| "--all".to_string()),
                preview_program: args
                    .next()
                    .unwrap_or_else(|| "zellij-pane-picker".to_string()),
            }),
            Some("helper-focus-underlying") => Ok(Self::HelperFocusUnderlying),
            Some("helper-close") => Ok(Self::HelperClose {
                session: args.next().unwrap_or_default(),
                pane_id: args.next().unwrap_or_default(),
            }),
            Some("plugin-switch") => Ok(Self::PluginSwitch(SwitchArgs::from_args(args))),
            Some("sidecar-plan") => Ok(Self::SidecarPlan(SwitchArgs::from_args(args))),
            Some("sidecar-prepare") => Ok(Self::SidecarPrepare(SwitchArgs::from_args(args))),
            Some("sidecar-wait-attached") => {
                let session = args.next().unwrap_or_default();
                let previous_count = args
                    .next()
                    .unwrap_or_default()
                    .parse::<u32>()
                    .map_err(|_| "invalid previous client count".to_string())?;
                Ok(Self::SidecarWaitAttached {
                    session,
                    previous_count,
                })
            }
            Some("sidecar-run") => Ok(Self::SidecarRun(SwitchArgs::from_args(args))),
            _ => Err(usage()),
        }
    }

    fn execute(self) -> Result<u8, String> {
        let runtime = outbound::Runtime::from_env();

        match self {
            Self::Toggle => feature::toggle::run(&runtime),
            Self::ContextToggleRun => feature::context_toggle::run(&runtime),
            Self::Navigate { target_json } => feature::navigate::run(&runtime, &target_json),
            Self::RecordCurrent { reason } => feature::record_current::run(&runtime, &reason),
            Self::Repo => feature::repo::run(&runtime),
            Self::RepoTo { repo } => feature::repo::run_to(&runtime, &repo),
            Self::Diagnose => print_output(feature::diagnose::run(&runtime)),
            Self::PickerCandidates { mode } => {
                print_output(feature::picker::candidates(&runtime, &mode))
            }
            Self::PickerTarget { selection } => {
                let output = feature::picker::target_from_selection(&selection)?;
                println!("{output}");
                Ok(0)
            }
            Self::PickerCommand { command_id } => {
                feature::picker::run_command(&runtime, &command_id)
            }
            Self::PickerPreview(args) => {
                print!(
                    "{}",
                    feature::picker::preview(
                        &runtime,
                        &args.kind,
                        &args.session,
                        &args.tab_id,
                        &args.pane_id,
                        &args.command_id,
                        &args.label,
                    )
                );
                Ok(0)
            }
            Self::PickerRun {
                mode,
                preview_program,
            } => feature::picker::run(&runtime, &mode, &preview_program),
            Self::HelperFocusUnderlying => feature::helper::focus_underlying(&runtime),
            Self::HelperClose { session, pane_id } => {
                feature::helper::close(&runtime, &session, &pane_id)
            }
            Self::PluginSwitch(args) => plugin_switch(&runtime, args),
            Self::SidecarPlan(args) => sidecar_plan(args),
            Self::SidecarPrepare(args) => sidecar_prepare(&runtime, args),
            Self::SidecarWaitAttached {
                session,
                previous_count,
            } => {
                let exit = feature::sidecar::wait_attached(
                    &runtime,
                    &session,
                    previous_count,
                    feature::sidecar::WaitPolicy::from_env(),
                )?;
                print_exit(exit)
            }
            Self::SidecarRun(args) => sidecar_launch(&runtime, args),
        }
    }
}

impl SwitchArgs {
    fn from_args(mut args: impl Iterator<Item = String>) -> Self {
        Self {
            session: args.next().unwrap_or_default(),
            kind: args.next().unwrap_or_else(|| "session".to_string()),
            tab_id: args.next().unwrap_or_default(),
            pane_id: args.next().unwrap_or_default(),
        }
    }
}

impl ScriptAlias {
    fn parse(raw_args: &[String]) -> Option<Self> {
        let argv0 = raw_args.first()?;
        let name = Path::new(argv0).file_name()?.to_str()?;

        match name {
            "zellij-nav" => None,
            "zellij-pane-picker" => Some(Self::PanePicker),
            "zellij-context-toggle" => Some(Self::ContextToggle),
            "zellij-nav-diagnose-context" => Some(Self::DiagnoseContext),
            "zellij-nav-plugin-switch" => Some(Self::PluginSwitch),
            "zellij-nav-sidecar" => Some(Self::Sidecar),
            _ => None,
        }
    }

    fn execute(self, raw_args: &[String]) -> Result<u8, String> {
        let argv0 = raw_args.first().map(String::as_str).unwrap_or("zellij-nav");
        let args = raw_args.iter().skip(1).cloned().collect::<Vec<_>>();
        let runtime = outbound::Runtime::from_env();

        match self {
            Self::PanePicker => picker_alias(&runtime, argv0, &args),
            Self::ContextToggle => feature::context_toggle::run(&runtime),
            Self::DiagnoseContext => print_output(feature::diagnose::run(&runtime)),
            Self::PluginSwitch => plugin_switch(&runtime, SwitchArgs::from_args(args.into_iter())),
            Self::Sidecar => sidecar_launch(&runtime, SwitchArgs::from_args(args.into_iter())),
        }
    }
}

fn picker_alias(runtime: &outbound::Runtime, argv0: &str, args: &[String]) -> Result<u8, String> {
    let mode = args.first().map(String::as_str).unwrap_or("--all");
    if mode == "--render-preview" {
        print!(
            "{}",
            feature::picker::preview(
                runtime,
                args.get(1).map(String::as_str).unwrap_or_default(),
                args.get(2).map(String::as_str).unwrap_or_default(),
                args.get(3).map(String::as_str).unwrap_or_default(),
                args.get(4).map(String::as_str).unwrap_or_default(),
                args.get(5).map(String::as_str).unwrap_or_default(),
                args.get(6).map(String::as_str).unwrap_or_default(),
            )
        );
        return Ok(0);
    }

    if mode == "--session-manager" {
        return feature::picker::run_command(runtime, "session-manager");
    }

    feature::picker::run(runtime, mode, argv0)
}

fn plugin_switch(runtime: &outbound::Runtime, args: SwitchArgs) -> Result<u8, String> {
    let target = args.plugin_target();
    let exit = match target {
        Ok(target) => feature::plugin_switch::run(runtime, target),
        Err(exit) => Ok(exit),
    }?;
    print_exit(exit)
}

fn sidecar_plan(args: SwitchArgs) -> Result<u8, String> {
    let target = args.sidecar_target();
    let exit = match target {
        Ok(target) => feature::sidecar::run(target),
        Err(exit) => exit,
    };
    print_exit(exit)
}

fn sidecar_prepare(runtime: &outbound::Runtime, args: SwitchArgs) -> Result<u8, String> {
    let target = args.sidecar_target();
    let exit = match target {
        Ok(target) => feature::sidecar::prepare(runtime, target),
        Err(exit) => Ok(exit),
    }?;
    print_exit(exit)
}

fn sidecar_launch(runtime: &outbound::Runtime, args: SwitchArgs) -> Result<u8, String> {
    let target = args.sidecar_target();
    let exit = match target {
        Ok(target) => feature::sidecar::launch(
            runtime,
            target,
            feature::sidecar::WaitPolicy::from_env(),
            feature::sidecar::StatusPolicy::from_env(),
        ),
        Err(exit) => Err(exit),
    };
    match exit {
        Ok(exit) | Err(exit) => print_exit(exit),
    }
}

impl SwitchArgs {
    fn plugin_target(
        self,
    ) -> Result<feature::plugin_switch::SwitchTarget, feature::plugin_switch::SwitchExit> {
        feature::plugin_switch::target_from_args(self.session, self.kind, self.tab_id, self.pane_id)
    }

    fn sidecar_target(
        self,
    ) -> Result<feature::sidecar::SidecarTarget, feature::sidecar::SidecarExit> {
        feature::sidecar::target_from_args(self.session, self.kind, self.tab_id, self.pane_id)
    }
}

fn print_output(result: Result<String, String>) -> Result<u8, String> {
    let output = result?;
    print!("{output}");
    Ok(0)
}

fn print_exit(exit: impl Into<ProcessExit>) -> Result<u8, String> {
    let exit = exit.into();
    print!("{}", exit.stdout);
    eprint!("{}", exit.stderr);
    Ok(exit.code)
}

struct ProcessExit {
    code: u8,
    stdout: String,
    stderr: String,
}

impl From<feature::plugin_switch::SwitchExit> for ProcessExit {
    fn from(exit: feature::plugin_switch::SwitchExit) -> Self {
        Self {
            code: exit.code,
            stdout: exit.stdout,
            stderr: exit.stderr,
        }
    }
}

impl From<feature::sidecar::SidecarExit> for ProcessExit {
    fn from(exit: feature::sidecar::SidecarExit) -> Self {
        Self {
            code: exit.code,
            stdout: exit.stdout,
            stderr: exit.stderr,
        }
    }
}

fn exit(result: Result<u8, String>) -> ExitCode {
    match result {
        Ok(code) => ExitCode::from(code),
        Err(err) => {
            eprintln!("zellij-nav: {err}");
            ExitCode::from(1)
        }
    }
}

fn usage() -> String {
    "usage: zellij-nav <toggle|context-toggle-run|navigate TARGET_JSON|record-current REASON|repo [REPO]|repo-to REPO|diagnose|picker-candidates MODE|picker-target SELECTION|picker-command COMMAND_ID|picker-preview KIND SESSION TAB_ID PANE_ID COMMAND_ID LABEL|picker-run MODE PREVIEW_PROGRAM|helper-focus-underlying|helper-close SESSION PANE_ID|plugin-switch SESSION KIND TAB_ID PANE_ID|sidecar-plan SESSION KIND TAB_ID PANE_ID|sidecar-prepare SESSION KIND TAB_ID PANE_ID|sidecar-wait-attached SESSION PREVIOUS_CLIENT_COUNT|sidecar-run SESSION KIND TAB_ID PANE_ID>".to_string()
}
