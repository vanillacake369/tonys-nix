pub const OK: u8 = 0;
pub const USAGE: u8 = 64;
pub const NOT_FOUND: u8 = 66;
pub const MISSING_COMMAND: u8 = 127;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SidecarKind {
    Session,
    Tab,
    Pane,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Prep {
    None,
    Tab { tab_id: u32 },
    Pane { tab_id: u32, pane_id: u32 },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SidecarTarget {
    pub session: String,
    pub kind: SidecarKind,
    pub prep: Prep,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SidecarPlan {
    pub target: SidecarTarget,
    pub launch: LaunchRoute,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum LaunchRoute {
    Wezterm,
    CliSpawn,
    StartProcess,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LaunchRequest {
    pub session: String,
    pub cwd: String,
    pub wezterm_pane: Option<String>,
    pub status_file: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LaunchOutcome {
    pub route: LaunchRoute,
    pub launch_ref: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LaunchFailure {
    pub status: u8,
    pub output: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum RunnerStatus {
    Missing,
    Ok,
    Failed(String),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SidecarExit {
    pub code: u8,
    pub stdout: String,
    pub stderr: String,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct WaitPolicy {
    pub max_attempts: u32,
    pub required_stable_count: u32,
    pub interval_seconds: f32,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub struct StatusPolicy {
    pub max_attempts: u32,
    pub interval_seconds: f32,
}

impl WaitPolicy {
    pub fn from_env() -> Self {
        Self {
            max_attempts: read_env_u32("ZELLIJ_NAV_SIDECAR_CLIENT_ATTEMPTS", 80),
            required_stable_count: read_env_u32("ZELLIJ_NAV_SIDECAR_STABLE_CLIENT_CHECKS", 10),
            interval_seconds: read_env_f32("ZELLIJ_NAV_SIDECAR_STATUS_INTERVAL_SECONDS", 0.1),
        }
    }
}

impl StatusPolicy {
    pub fn from_env() -> Self {
        Self {
            max_attempts: read_env_u32("ZELLIJ_NAV_SIDECAR_STATUS_ATTEMPTS", 80),
            interval_seconds: read_env_f32("ZELLIJ_NAV_SIDECAR_STATUS_INTERVAL_SECONDS", 0.1),
        }
    }
}

pub trait SidecarPort {
    fn command_exists(&self, command: &str) -> bool;
    fn session_exists(&self, session: &str) -> bool;
    fn tab_position(&self, session: &str, tab_id: u32) -> Option<u32>;
    fn current_dir(&self) -> String;
    fn env_var(&self, name: &str) -> Option<String>;
    fn make_temp_path(&self, name: &str) -> Result<String, String>;
    fn remove_file(&self, path: &str);
    fn runner_status(&self, path: &str) -> RunnerStatus;
    fn spawn_cli(&self, request: &LaunchRequest) -> Result<String, LaunchFailure>;
    fn spawn_start(
        &self,
        request: &LaunchRequest,
        launch_log_file: &str,
    ) -> Result<String, LaunchFailure>;
    fn go_to_tab(&self, session: &str, tab_id: u32) -> Result<(), String>;
    fn focus_pane(&self, session: &str, pane_id: u32) -> Result<(), String>;
    fn count_session_clients(&self, session: &str) -> Result<u32, String>;
    fn sleep_seconds(&self, seconds: f32);
}

pub fn run(target: SidecarTarget) -> SidecarExit {
    let plan = SidecarPlan {
        target,
        launch: LaunchRoute::Wezterm,
    };

    SidecarExit {
        code: OK,
        stdout: format_plan(&plan),
        stderr: String::new(),
    }
}

pub fn prepare(port: &impl SidecarPort, target: SidecarTarget) -> Result<SidecarExit, String> {
    match target.prep {
        Prep::None => {}
        Prep::Tab { tab_id } => {
            port.go_to_tab(&target.session, tab_id)?;
        }
        Prep::Pane { tab_id, pane_id } => {
            port.go_to_tab(&target.session, tab_id)?;
            port.focus_pane(&target.session, pane_id)?;
        }
    }

    Ok(SidecarExit {
        code: OK,
        stdout: format!("prepared session={}\n", target.session),
        stderr: String::new(),
    })
}

pub fn launch(
    port: &impl SidecarPort,
    target: SidecarTarget,
    wait_policy: WaitPolicy,
    status_policy: StatusPolicy,
) -> Result<SidecarExit, SidecarExit> {
    validate_runtime(port, &target)?;

    let tab_position = match target.prep {
        Prep::Tab { tab_id } => port
            .tab_position(&target.session, tab_id)
            .ok_or_else(|| {
                runtime_err(
                    NOT_FOUND,
                    &format!("tab not found: session={} tab={tab_id}", target.session),
                )
            })?
            .to_string(),
        _ => String::new(),
    };

    let initial_clients = port
        .count_session_clients(&target.session)
        .map_err(|err| runtime_err(1, &err))?;
    let status_file = port
        .make_temp_path("zellij-nav-sidecar.status")
        .map_err(|err| runtime_err(1, &err))?;
    let launch_log_file = port
        .make_temp_path("zellij-nav-sidecar.launch")
        .map_err(|err| runtime_err(1, &err))?;
    port.remove_file(&status_file);
    port.remove_file(&launch_log_file);

    let request = LaunchRequest {
        session: target.session.clone(),
        cwd: sidecar_cwd(port),
        wezterm_pane: port
            .env_var("WEZTERM_PANE")
            .filter(|value| !value.is_empty()),
        status_file: status_file.clone(),
    };

    // SAFETY: protected client에서는 기존 Zellij client를 직접 switch하지 않는다.
    // 먼저 새 client attach가 관측되는 route를 시도하고, 실패할 때만 별도 process route로
    // 내려가서 long-running foreground PTY를 보존한다.
    let outcome = match launch_cli_route(port, &target, &request, initial_clients, wait_policy) {
        Ok(outcome) => {
            port.remove_file(&status_file);
            port.remove_file(&launch_log_file);
            return Ok(format_launch(&target, &outcome, &tab_position));
        }
        Err(cli_failure) => launch_start_route(
            port,
            &target,
            &request,
            &launch_log_file,
            cli_failure,
            initial_clients,
            wait_policy,
            status_policy,
        )?,
    };

    port.remove_file(&status_file);
    port.remove_file(&launch_log_file);
    Ok(format_launch(&target, &outcome, &tab_position))
}

pub fn wait_attached(
    port: &impl SidecarPort,
    session: &str,
    previous_count: u32,
    policy: WaitPolicy,
) -> Result<SidecarExit, String> {
    if policy.required_stable_count == 0 {
        return Ok(wait_ok(session));
    }

    let mut stable_count = 0;
    for _ in 0..policy.max_attempts {
        let count = port.count_session_clients(session)?;
        if count > previous_count {
            stable_count += 1;
            if stable_count >= policy.required_stable_count {
                return Ok(wait_ok(session));
            }
        } else {
            stable_count = 0;
        }
        port.sleep_seconds(policy.interval_seconds);
    }

    Err(format!(
        "sidecar attach failed: session={session} initial_clients={previous_count}"
    ))
}

pub fn target_from_args(
    session: String,
    kind: String,
    tab_id: String,
    pane_id: String,
) -> Result<SidecarTarget, SidecarExit> {
    if session.is_empty() {
        return Err(err("missing session"));
    }

    let kind = match kind.as_str() {
        "session" => SidecarKind::Session,
        "tab" => SidecarKind::Tab,
        "pane" => SidecarKind::Pane,
        other => return Err(err(&format!("unsupported kind: {other}"))),
    };
    let tab_id = parse_optional_u32(&tab_id, "tab")?;
    let pane_id = parse_optional_u32(&pane_id, "pane")?;
    let prep = match kind {
        SidecarKind::Session => Prep::None,
        SidecarKind::Tab => Prep::Tab {
            tab_id: tab_id.ok_or_else(|| err("missing tab id"))?,
        },
        SidecarKind::Pane => Prep::Pane {
            tab_id: tab_id.ok_or_else(|| err("missing tab id"))?,
            pane_id: pane_id.ok_or_else(|| err("missing pane id"))?,
        },
    };

    Ok(SidecarTarget {
        session,
        kind,
        prep,
    })
}

fn format_plan(plan: &SidecarPlan) -> String {
    let kind = kind_name(&plan.target.kind);
    let (tab_id, pane_id) = match plan.target.prep {
        Prep::None => (String::new(), String::new()),
        Prep::Tab { tab_id } => (tab_id.to_string(), String::new()),
        Prep::Pane { tab_id, pane_id } => (tab_id.to_string(), pane_id.to_string()),
    };

    format!(
        "route=wezterm session={} kind={} tab={} pane={}\n",
        plan.target.session, kind, tab_id, pane_id
    )
}

fn validate_runtime(port: &impl SidecarPort, target: &SidecarTarget) -> Result<(), SidecarExit> {
    if !port.command_exists("wezterm") {
        return Err(runtime_err(MISSING_COMMAND, "wezterm not found"));
    }
    if !port.command_exists("zellij") {
        return Err(runtime_err(MISSING_COMMAND, "zellij not found"));
    }
    if !target.session.is_empty() && port.session_exists(&target.session) {
        return Ok(());
    }
    Err(runtime_err(
        NOT_FOUND,
        &format!("session not found: {}", target.session),
    ))
}

fn launch_cli_route(
    port: &impl SidecarPort,
    target: &SidecarTarget,
    request: &LaunchRequest,
    initial_clients: u32,
    wait_policy: WaitPolicy,
) -> Result<LaunchOutcome, LaunchFailure> {
    prepare(port, target.clone()).map_err(|err| LaunchFailure {
        status: 1,
        output: err,
    })?;

    let launch_ref = port.spawn_cli(request)?;
    wait_attached(port, &target.session, initial_clients, wait_policy).map_err(|err| {
        LaunchFailure {
            status: 1,
            output: err,
        }
    })?;

    Ok(LaunchOutcome {
        route: LaunchRoute::CliSpawn,
        launch_ref,
    })
}

#[allow(clippy::too_many_arguments)]
fn launch_start_route(
    port: &impl SidecarPort,
    target: &SidecarTarget,
    request: &LaunchRequest,
    launch_log_file: &str,
    cli_failure: LaunchFailure,
    initial_clients: u32,
    wait_policy: WaitPolicy,
    status_policy: StatusPolicy,
) -> Result<LaunchOutcome, SidecarExit> {
    prepare(port, target.clone()).map_err(|err| runtime_err(1, &err))?;

    let launch_ref = port
        .spawn_start(request, launch_log_file)
        .map_err(|start_failure| {
            runtime_err(
                1,
                &format!(
                    "wezterm launch failed: cli_spawn_status={} cli_output={} start_output={}",
                    cli_failure.status,
                    one_line(&cli_failure.output),
                    one_line(&start_failure.output)
                ),
            )
        })?;

    wait_for_runner(port, &request.status_file, status_policy)?;
    wait_attached(port, &target.session, initial_clients, wait_policy).map_err(|err| {
        runtime_err(
            1,
            &format!(
                "{err}: route=start-process launch_ref={} launch_log={}",
                one_line(&launch_ref),
                one_line(&read_launch_log(port, launch_log_file))
            ),
        )
    })?;

    Ok(LaunchOutcome {
        route: LaunchRoute::StartProcess,
        launch_ref,
    })
}

fn wait_for_runner(
    port: &impl SidecarPort,
    status_file: &str,
    policy: StatusPolicy,
) -> Result<(), SidecarExit> {
    for _ in 0..policy.max_attempts {
        match port.runner_status(status_file) {
            RunnerStatus::Missing => port.sleep_seconds(policy.interval_seconds),
            RunnerStatus::Ok => return Ok(()),
            RunnerStatus::Failed(status) => {
                return Err(runtime_err(1, &format!("sidecar runner failed: {status}")));
            }
        }
    }

    Err(runtime_err(
        1,
        "sidecar runner timed out: route=start-process",
    ))
}

fn format_launch(
    target: &SidecarTarget,
    outcome: &LaunchOutcome,
    tab_position: &str,
) -> SidecarExit {
    let kind = kind_name(&target.kind);
    let (tab_id, pane_id) = match target.prep {
        Prep::None => (String::new(), String::new()),
        Prep::Tab { tab_id } => (tab_id.to_string(), String::new()),
        Prep::Pane { tab_id, pane_id } => (tab_id.to_string(), pane_id.to_string()),
    };

    SidecarExit {
        code: OK,
        stdout: format!(
            "route={} launch_ref={} session={} kind={} tab={} tab_position={} pane={}\n",
            route_name(&outcome.route),
            outcome.launch_ref.trim(),
            target.session,
            kind,
            tab_id,
            tab_position,
            pane_id
        ),
        stderr: String::new(),
    }
}

fn route_name(route: &LaunchRoute) -> &'static str {
    match route {
        LaunchRoute::Wezterm => "wezterm",
        LaunchRoute::CliSpawn => "cli-spawn",
        LaunchRoute::StartProcess => "start-process",
    }
}

fn parse_optional_u32(value: &str, name: &str) -> Result<Option<u32>, SidecarExit> {
    if value.is_empty() || value == "null" {
        return Ok(None);
    }
    value
        .parse::<u32>()
        .map(Some)
        .map_err(|_| err(&format!("invalid {name} id: {value}")))
}

fn kind_name(kind: &SidecarKind) -> &'static str {
    match kind {
        SidecarKind::Session => "session",
        SidecarKind::Tab => "tab",
        SidecarKind::Pane => "pane",
    }
}

fn err(message: &str) -> SidecarExit {
    SidecarExit {
        code: USAGE,
        stdout: String::new(),
        stderr: format!("{message}\n"),
    }
}

fn runtime_err(code: u8, message: &str) -> SidecarExit {
    SidecarExit {
        code,
        stdout: String::new(),
        stderr: format!("{message}\n"),
    }
}

fn wait_ok(session: &str) -> SidecarExit {
    SidecarExit {
        code: OK,
        stdout: format!("attached session={session}\n"),
        stderr: String::new(),
    }
}

fn read_env_u32(name: &str, default: u32) -> u32 {
    std::env::var(name)
        .ok()
        .and_then(|value| value.parse::<u32>().ok())
        .unwrap_or(default)
}

fn read_env_f32(name: &str, default: f32) -> f32 {
    std::env::var(name)
        .ok()
        .and_then(|value| value.parse::<f32>().ok())
        .unwrap_or(default)
}

fn sidecar_cwd(port: &impl SidecarPort) -> String {
    port.env_var("ZELLIJ_NAV_SIDECAR_CWD")
        .filter(|value| !value.is_empty())
        .unwrap_or_else(|| port.current_dir())
}

fn read_launch_log(port: &impl SidecarPort, path: &str) -> String {
    match port.runner_status(path) {
        RunnerStatus::Failed(status) => status,
        _ => String::new(),
    }
}

fn one_line(value: &str) -> String {
    value
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ")
        .chars()
        .take(240)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    struct FakePort {
        calls: RefCell<Vec<String>>,
        counts: RefCell<Vec<u32>>,
    }

    impl FakePort {
        fn new() -> Self {
            Self {
                calls: RefCell::new(Vec::new()),
                counts: RefCell::new(Vec::new()),
            }
        }

        fn with_counts(counts: Vec<u32>) -> Self {
            Self {
                calls: RefCell::new(Vec::new()),
                counts: RefCell::new(counts),
            }
        }

        fn calls(&self) -> Vec<String> {
            self.calls.borrow().clone()
        }
    }

    impl SidecarPort for FakePort {
        fn command_exists(&self, _command: &str) -> bool {
            true
        }

        fn session_exists(&self, _session: &str) -> bool {
            true
        }

        fn tab_position(&self, _session: &str, _tab_id: u32) -> Option<u32> {
            Some(1)
        }

        fn current_dir(&self) -> String {
            "/tmp".to_string()
        }

        fn env_var(&self, _name: &str) -> Option<String> {
            None
        }

        fn make_temp_path(&self, name: &str) -> Result<String, String> {
            Ok(format!("/tmp/{name}"))
        }

        fn remove_file(&self, path: &str) {
            self.calls.borrow_mut().push(format!("remove_file:{path}"));
        }

        fn runner_status(&self, _path: &str) -> RunnerStatus {
            RunnerStatus::Ok
        }

        fn spawn_cli(&self, request: &LaunchRequest) -> Result<String, LaunchFailure> {
            self.calls.borrow_mut().push(format!(
                "spawn_cli:{}:{}:{:?}",
                request.session, request.cwd, request.wezterm_pane
            ));
            Ok("11".to_string())
        }

        fn spawn_start(
            &self,
            request: &LaunchRequest,
            launch_log_file: &str,
        ) -> Result<String, LaunchFailure> {
            self.calls.borrow_mut().push(format!(
                "spawn_start:{}:{}:{launch_log_file}",
                request.session, request.cwd
            ));
            Ok("wezterm_start_pid=12".to_string())
        }

        fn go_to_tab(&self, session: &str, tab_id: u32) -> Result<(), String> {
            self.calls
                .borrow_mut()
                .push(format!("go_to_tab:{session}:{tab_id}"));
            Ok(())
        }

        fn focus_pane(&self, session: &str, pane_id: u32) -> Result<(), String> {
            self.calls
                .borrow_mut()
                .push(format!("focus_pane:{session}:{pane_id}"));
            Ok(())
        }

        fn count_session_clients(&self, session: &str) -> Result<u32, String> {
            self.calls
                .borrow_mut()
                .push(format!("count_session_clients:{session}"));
            Ok(self.counts.borrow_mut().remove(0))
        }

        fn sleep_seconds(&self, seconds: f32) {
            self.calls.borrow_mut().push(format!("sleep:{seconds}"));
        }
    }

    #[test]
    fn pane_target_requires_tab_and_pane_ids() {
        let missing_pane =
            target_from_args("target".into(), "pane".into(), "1".into(), "".into()).unwrap_err();

        assert_eq!(missing_pane.code, USAGE);
        assert!(missing_pane.stderr.contains("missing pane id"));
    }

    #[test]
    fn tab_target_builds_stable_prep_plan() {
        let target =
            target_from_args("target".into(), "tab".into(), "7".into(), "".into()).unwrap();

        assert_eq!(target.prep, Prep::Tab { tab_id: 7 });
        assert_eq!(
            run(target).stdout,
            "route=wezterm session=target kind=tab tab=7 pane=\n"
        );
    }

    #[test]
    fn invalid_numeric_id_is_usage_error() {
        let exit = target_from_args("target".into(), "pane".into(), "tab-a".into(), "7".into())
            .unwrap_err();

        assert_eq!(exit.code, USAGE);
        assert!(exit.stderr.contains("invalid tab id: tab-a"));
    }

    #[test]
    fn pane_prepare_goes_to_tab_before_focus() {
        let port = FakePort::new();
        let target =
            target_from_args("target".into(), "pane".into(), "0".into(), "7".into()).unwrap();

        let exit = prepare(&port, target).unwrap();

        assert_eq!(exit.code, OK);
        assert_eq!(
            port.calls(),
            vec!["go_to_tab:target:0", "focus_pane:target:7"]
        );
    }

    #[test]
    fn session_prepare_has_no_effects() {
        let port = FakePort::new();
        let target =
            target_from_args("target".into(), "session".into(), "".into(), "".into()).unwrap();

        prepare(&port, target).unwrap();

        assert!(port.calls().is_empty());
    }

    #[test]
    fn wait_attached_requires_consecutive_counts_above_initial() {
        let port = FakePort::with_counts(vec![1, 2, 1, 2, 2]);
        let policy = WaitPolicy {
            max_attempts: 5,
            required_stable_count: 2,
            interval_seconds: 0.0,
        };

        let exit = wait_attached(&port, "target", 1, policy).unwrap();

        assert_eq!(exit.stdout, "attached session=target\n");
        assert_eq!(
            port.calls(),
            vec![
                "count_session_clients:target",
                "sleep:0",
                "count_session_clients:target",
                "sleep:0",
                "count_session_clients:target",
                "sleep:0",
                "count_session_clients:target",
                "sleep:0",
                "count_session_clients:target",
            ]
        );
    }

    #[test]
    fn wait_attached_times_out_without_stable_client() {
        let port = FakePort::with_counts(vec![1, 2, 1]);
        let policy = WaitPolicy {
            max_attempts: 3,
            required_stable_count: 2,
            interval_seconds: 0.0,
        };

        let err = wait_attached(&port, "target", 1, policy).unwrap_err();

        assert!(err.contains("sidecar attach failed"));
    }

    #[test]
    fn launch_uses_cli_spawn_before_start_route() {
        let port = FakePort::with_counts(vec![1, 2]);
        let target =
            target_from_args("target".into(), "session".into(), "".into(), "".into()).unwrap();
        let wait_policy = WaitPolicy {
            max_attempts: 2,
            required_stable_count: 1,
            interval_seconds: 0.0,
        };

        let exit = launch(
            &port,
            target,
            wait_policy,
            StatusPolicy {
                max_attempts: 1,
                interval_seconds: 0.0,
            },
        )
        .unwrap();

        assert!(exit.stdout.contains("route=cli-spawn"));
        assert!(port
            .calls()
            .iter()
            .any(|call| call.starts_with("spawn_cli")));
        assert!(!port
            .calls()
            .iter()
            .any(|call| call.starts_with("spawn_start")));
    }
}
