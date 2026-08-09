use crate::domain::{Location, Target, TargetKind};
use crate::feature::context_toggle::ContextTogglePort;
use crate::feature::diagnose::DiagnosePort;
use crate::feature::helper::HelperPort;
use crate::feature::navigate::{ApplyResult as NavigateApplyResult, NavigatePort};
use crate::feature::picker::{PickerAction, PickerPort};
use crate::feature::plugin_switch::PluginSwitchPort;
use crate::feature::record_current::RecordPort;
use crate::feature::sidecar::{LaunchFailure, LaunchRequest, RunnerStatus, SidecarPort};
use crate::feature::toggle::{ApplyResult, LockGuard, Route, TogglePort};
use serde_json::Value;
use std::fs;
use std::fs::File;
use std::io::Write;
#[cfg(unix)]
use std::os::unix::fs::FileTypeExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::{SystemTime, UNIX_EPOCH};

pub struct Runtime {
    state_dir: PathBuf,
    previous_file: PathBuf,
    log_file: PathBuf,
    lock_dir: PathBuf,
    protected_pattern: String,
    protected_strategy: String,
    sidecar_command: PathBuf,
    plugin_switch_command: PathBuf,
    plugin_url: String,
    plugin_grace_seconds: f32,
}

impl Runtime {
    pub fn from_env() -> Self {
        let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
        let config_dir = std::env::var("XDG_CONFIG_HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from(&home).join(".config"));
        let state_dir = std::env::var("ZELLIJ_NAV_STATE_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|_| {
                let base = std::env::var("XDG_STATE_HOME")
                    .map(PathBuf::from)
                    .unwrap_or_else(|_| PathBuf::from(home).join(".local/state"));
                base.join("zellij-workspace")
            });
        let log_file = std::env::var("ZELLIJ_NAV_LOG_FILE")
            .map(PathBuf::from)
            .unwrap_or_else(|_| {
                std::env::var("ZELLIJ_NAV_LOG_DIR")
                    .map(PathBuf::from)
                    .or_else(|_| std::env::var("ZELLIJ_NAV_STATE_DIR").map(|_| state_dir.clone()))
                    .unwrap_or_else(|_| config_dir.join("zellij").join("log"))
                    .join("zellij-navigation.log")
            });
        let script_dir = std::env::current_exe()
            .ok()
            .and_then(|path| path.parent().map(Path::to_path_buf))
            .unwrap_or_else(|| PathBuf::from("."));

        Self {
            previous_file: state_dir.join("previous-target.json"),
            log_file,
            lock_dir: state_dir.join(".navigation.lock"),
            state_dir,
            protected_pattern: std::env::var("ZELLIJ_NAV_PROTECTED_COMMAND_PATTERN")
                .unwrap_or_else(|_| "(^|[[:space:]/])(codex|cdx)([[:space:]]|$)".to_string()),
            protected_strategy: std::env::var("ZELLIJ_NAV_PROTECTED_STRATEGY")
                .unwrap_or_else(|_| "block".to_string()),
            sidecar_command: std::env::var("ZELLIJ_NAV_SIDECAR_COMMAND")
                .map(PathBuf::from)
                .unwrap_or_else(|_| script_dir.join("zellij-nav-sidecar")),
            plugin_switch_command: std::env::var("ZELLIJ_NAV_PLUGIN_SWITCH_COMMAND")
                .map(PathBuf::from)
                .unwrap_or_else(|_| script_dir.join("zellij-nav-plugin-switch")),
            plugin_url: std::env::var("ZELLIJ_NAV_PLUGIN_URL").unwrap_or_else(|_| {
                format!(
                    "file:{}",
                    script_dir
                        .join("../plugins/zellij-nav-switcher.wasm")
                        .to_string_lossy()
                )
            }),
            plugin_grace_seconds: std::env::var("ZELLIJ_NAV_PLUGIN_GRACE_SECONDS")
                .ok()
                .and_then(|value| value.parse::<f32>().ok())
                .unwrap_or(0.25),
        }
    }

    fn log(&self, message: &str) {
        if let Some(parent) = self.log_file.parent() {
            let _ = fs::create_dir_all(parent);
        }
        rotate_log_if_needed(&self.log_file);
        let stamp = chrono_like_stamp();
        let _ = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_file)
            .and_then(|mut file| {
                use std::io::Write;
                writeln!(file, "{stamp} {message}")
            });
    }

    fn current_session(&self) -> Option<String> {
        let output = run_output(Command::new("zellij").args(["list-sessions", "--no-formatting"]));
        output
            .lines()
            .find(|line| line.contains("(current)"))
            .and_then(|line| line.split_whitespace().next())
            .map(str::to_string)
            .or_else(|| std::env::var("ZELLIJ_SESSION_NAME").ok())
    }

    fn session_exists(&self, session: &str) -> bool {
        let output = run_output(Command::new("zellij").args(["list-sessions", "--no-formatting"]));
        output
            .lines()
            .any(|line| !line.contains("EXITED") && line.split_whitespace().next() == Some(session))
    }

    fn panes(&self, session: &str) -> Vec<Value> {
        let output = run_output(
            Command::new("zellij")
                .args(["--session", session, "action", "list-panes"])
                .args(["--json", "--all", "--tab", "--state", "--command"]),
        );
        serde_json::from_str::<Vec<Value>>(&output).unwrap_or_default()
    }

    fn target_from_location(&self) -> Option<Target> {
        let session = self.current_session()?;
        let panes = self.panes(&session);
        let self_pane = std::env::var("ZELLIJ_PANE_ID").ok();

        if std::env::var("ZELLIJ_NAV_HELPER").ok().as_deref() != Some("1") {
            if let Some(target) = self.pane_target(&session, &panes, self_pane.as_deref(), false) {
                return Some(target);
            }
        }

        self.pane_target(&session, &panes, self_pane.as_deref(), true)
            .or_else(|| {
                Some(Target::from_location(Location {
                    session: session.clone(),
                    tab_id: None,
                    pane_id: None,
                    label: session,
                }))
            })
    }

    fn pane_target(
        &self,
        session: &str,
        panes: &[Value],
        self_pane: Option<&str>,
        focused: bool,
    ) -> Option<Target> {
        panes.iter().find_map(|pane| {
            if !selectable_terminal(pane) {
                return None;
            }

            let id = pane.get("id")?.as_u64()? as u32;
            let is_match = if focused {
                pane.get("is_focused").and_then(Value::as_bool) == Some(true)
                    && Some(id.to_string()) != self_pane.map(str::to_string)
            } else {
                Some(id.to_string()) == self_pane.map(str::to_string)
            };

            if !is_match {
                return None;
            }

            Some(Target {
                kind: TargetKind::Pane,
                session: session.to_string(),
                tab_id: pane
                    .get("tab_id")
                    .and_then(Value::as_u64)
                    .map(|id| id as u32),
                pane_id: Some(id),
                label: pane_label(pane),
            })
        })
    }

    fn focused_target(&self) -> Option<Target> {
        let session = self.current_session()?;
        let panes = self.panes(&session);

        panes.iter().find_map(|pane| {
            if !selectable_terminal(pane) {
                return None;
            }
            if pane.get("is_focused").and_then(Value::as_bool) != Some(true) {
                return None;
            }

            let id = pane.get("id")?.as_u64()? as u32;
            Some(Target {
                kind: TargetKind::Pane,
                session: session.clone(),
                tab_id: pane
                    .get("tab_id")
                    .and_then(Value::as_u64)
                    .map(|id| id as u32),
                pane_id: Some(id),
                label: pane_label(pane),
            })
        })
    }

    fn focused_location(&self) -> Option<Location> {
        self.focused_target().map(|target| Location {
            session: target.session,
            tab_id: target.tab_id,
            pane_id: target.pane_id,
            label: target.label,
        })
    }

    fn visible_pane_state(&self) -> Vec<Value> {
        let output = run_output(Command::new("zellij").args(["action", "list-panes"]).args([
            "--json",
            "--all",
            "--tab",
            "--state",
            "--command",
        ]));
        serde_json::from_str::<Vec<Value>>(&output).unwrap_or_default()
    }

    fn tabs(&self, session: &str) -> Vec<Value> {
        let output = run_output(
            Command::new("zellij")
                .args(["--session", session, "action", "list-tabs"])
                .args(["--json", "--state", "--panes"]),
        );
        serde_json::from_str::<Vec<Value>>(&output).unwrap_or_default()
    }

    fn current_context_is_protected(&self) -> bool {
        if self.current_client_is_protected() {
            return true;
        }

        let Some(session) = self.current_session() else {
            return false;
        };

        let self_pane = std::env::var("ZELLIJ_PANE_ID").ok();
        let helper = std::env::var("ZELLIJ_NAV_HELPER").ok().as_deref() == Some("1");

        self.panes(&session).iter().any(|pane| {
            if !selectable_terminal(pane) {
                return false;
            }

            let id = pane
                .get("id")
                .and_then(Value::as_u64)
                .map(|id| id.to_string());
            let focused = pane.get("is_focused").and_then(Value::as_bool) == Some(true);
            let current_context = if helper {
                focused && id != self_pane
            } else {
                id == self_pane || (self_pane.is_none() && focused)
            };

            current_context && pane_is_protected(pane, &self.protected_pattern)
        })
    }

    fn current_client_is_protected(&self) -> bool {
        let Some(self_pane) = std::env::var("ZELLIJ_PANE_ID").ok() else {
            return false;
        };
        let pane = format!("terminal_{self_pane}");
        let clients = run_output(Command::new("zellij").args(["action", "list-clients"]));

        clients.lines().skip(1).any(|line| {
            let fields = line.split_whitespace().collect::<Vec<_>>();
            if fields.get(1).copied() != Some(pane.as_str()) {
                return false;
            }
            let command = fields
                .get(2..)
                .map(|parts| parts.join(" "))
                .unwrap_or_default();
            protected_match(&command, &self.protected_pattern)
        })
    }

    fn focus_target(&self, target: &Target) -> ApplyResult {
        if !self.session_exists(&target.session) {
            return ApplyResult::SessionMissing;
        }

        match target.kind {
            TargetKind::Session => self.focus_session(&target.session),
            TargetKind::Tab => self.focus_tab(target),
            TargetKind::Pane => self.focus_pane(target),
        }
    }

    fn focus_session(&self, session: &str) -> ApplyResult {
        if self.current_session().as_deref() == Some(session) {
            return ApplyResult::Noop;
        }

        if run_status(Command::new("zellij").args(["action", "switch-session", session])) {
            return ApplyResult::Moved;
        }
        ApplyResult::Failed
    }

    fn focus_tab(&self, target: &Target) -> ApplyResult {
        let Some(tab_id) = target.tab_id else {
            return self.focus_session(&target.session);
        };
        let current_session = self.current_session();
        let tab = tab_id.to_string();

        let ok = if current_session.as_deref() == Some(&target.session) {
            run_status(Command::new("zellij").args([
                "--session",
                &target.session,
                "action",
                "go-to-tab-by-id",
                &tab,
            ]))
        } else {
            run_status(Command::new("zellij").args([
                "--session",
                &target.session,
                "action",
                "go-to-tab-by-id",
                &tab,
            ])) && run_status(Command::new("zellij").args([
                "action",
                "switch-session",
                &target.session,
            ]))
        };

        if ok {
            return self.confirm_or_accept(target);
        }
        self.focus_session(&target.session)
    }

    fn focus_pane(&self, target: &Target) -> ApplyResult {
        let Some(pane_id) = target.pane_id else {
            return self.focus_tab(target);
        };
        let current_session = self.current_session();
        let pane = format!("terminal_{pane_id}");

        let ok = if current_session.as_deref() == Some(&target.session) {
            let Some(tab_id) = target.tab_id else {
                return ApplyResult::Failed;
            };
            let tab = tab_id.to_string();
            run_status(Command::new("zellij").args([
                "--session",
                &target.session,
                "action",
                "go-to-tab-by-id",
                &tab,
            ])) && run_status(Command::new("zellij").args([
                "--session",
                &target.session,
                "action",
                "focus-pane-id",
                &pane,
            ]))
        } else {
            run_status(Command::new("zellij").args([
                "action",
                "switch-session",
                &target.session,
                "--pane-id",
                &pane,
            ]))
        };

        if ok {
            return self.confirm_or_accept(target);
        }
        self.focus_tab(target)
    }

    fn confirm_or_accept(&self, target: &Target) -> ApplyResult {
        // DEBUG: floating helper 안에서는 Zellij CLI의 current/focus 관측이 helper
        // process 기준으로 흔들릴 수 있다. action 성공을 movement accepted로 처리하고,
        // non-helper 경로에서만 post-confirm을 수행한다.
        if std::env::var("ZELLIJ_NAV_HELPER").ok().as_deref() == Some("1") {
            return ApplyResult::Moved;
        }

        for _ in 0..5 {
            if <Self as TogglePort>::target_is_current(self, target).unwrap_or(false) {
                return ApplyResult::Moved;
            }
            std::thread::sleep(std::time::Duration::from_millis(50));
        }

        ApplyResult::Failed
    }
}

impl TogglePort for Runtime {
    fn acquire_lock(&self) -> Result<Box<dyn LockGuard + '_>, String> {
        fs::create_dir_all(&self.state_dir).map_err(|err| err.to_string())?;
        LeaseLock::acquire(self).map(|lock| Box::new(lock) as Box<dyn LockGuard>)
    }

    fn previous(&self) -> Result<Option<Target>, String> {
        let content = match fs::read_to_string(&self.previous_file) {
            Ok(content) => content,
            Err(err) if err.kind() == std::io::ErrorKind::NotFound => return Ok(None),
            Err(err) => return Err(err.to_string()),
        };
        match serde_json::from_str(&content) {
            Ok(target) if Target::valid(&target) => Ok(Some(target)),
            Ok(target) => {
                let reason = target.validation_reason();
                let _ = fs::remove_file(&self.previous_file);
                self.log(&format!("cleared previous-target reason={reason}"));
                Ok(None)
            }
            Err(err) => {
                let _ = fs::remove_file(&self.previous_file);
                self.log(&format!(
                    "cleared previous-target reason=invalid-json error={err}"
                ));
                Ok(None)
            }
        }
    }

    fn current(&self) -> Result<Option<Target>, String> {
        Ok(self.target_from_location())
    }

    fn target_is_current(&self, target: &Target) -> Result<bool, String> {
        Ok(self.focused_target().is_some_and(|current| {
            target.matches_location(&Location {
                session: current.session,
                tab_id: current.tab_id,
                pane_id: current.pane_id,
                label: current.label,
            })
        }))
    }

    fn route(&self, _target: &Target) -> Route {
        if !self.current_context_is_protected() {
            return Route::Cli;
        }

        match self.protected_strategy.as_str() {
            "plugin" => Route::Plugin,
            "plugin-sidecar" | "plugin_then_sidecar" | "plugin-then-sidecar" => {
                Route::PluginThenSidecar
            }
            "sidecar" => Route::Sidecar,
            _ => Route::Block,
        }
    }

    fn apply(&self, target: &Target, route: &Route) -> Result<ApplyResult, String> {
        if !self.session_exists(&target.session) {
            return Ok(ApplyResult::SessionMissing);
        }

        match route {
            Route::Block => {
                self.log(&format!(
                    "protected context blocked reason=no-client-scoped-zellij-mutation strategy=block target={}",
                    target.summary()
                ));
                Ok(ApplyResult::Failed)
            }
            Route::Cli => Ok(self.focus_target(target)),
            Route::Plugin => Ok(self.focus_with_plugin(target)),
            Route::PluginThenSidecar => Ok(self.focus_with_plugin_then_sidecar(target)),
            Route::Sidecar => Ok(self.focus_with_sidecar(target)),
        }
    }

    fn save_previous(&self, target: &Target) -> Result<(), String> {
        let json = serde_json::to_string(target).map_err(|err| err.to_string())?;
        fs::create_dir_all(&self.state_dir).map_err(|err| err.to_string())?;
        let tmp = self.state_dir.join(format!(
            ".previous-target.{}.{}",
            std::process::id(),
            now_seconds()
        ));
        // SAFETY: previous-target은 작은 JSON 하나지만 toggle/picker가 동시에 실행될 수
        // 있다. temp file + rename으로 lock 안의 write를 atomic commit처럼 유지한다.
        fs::write(&tmp, format!("{json}\n")).map_err(|err| err.to_string())?;
        fs::rename(&tmp, &self.previous_file).map_err(|err| {
            let _ = fs::remove_file(&tmp);
            err.to_string()
        })
    }

    fn clear_previous(&self, reason: &str) -> Result<(), String> {
        let _ = fs::remove_file(&self.previous_file);
        self.log(&format!("cleared previous-target reason={reason}"));
        Ok(())
    }

    fn log(&self, message: &str) {
        Runtime::log(self, message);
    }
}

impl NavigatePort for Runtime {
    fn acquire_navigation_lock(&self) -> Result<Box<dyn LockGuard + '_>, String> {
        <Self as TogglePort>::acquire_lock(self)
    }

    fn capture_origin(&self) -> Result<Option<Target>, String> {
        <Self as TogglePort>::current(self)
    }

    fn selected_is_current(&self, target: &Target) -> Result<bool, String> {
        <Self as TogglePort>::target_is_current(self, target)
    }

    fn apply_navigation(&self, target: &Target) -> Result<NavigateApplyResult, String> {
        let route = <Self as TogglePort>::route(self, target);
        let result = <Self as TogglePort>::apply(self, target, &route)?;
        Ok(match result {
            ApplyResult::Moved => NavigateApplyResult::Moved,
            ApplyResult::Noop => NavigateApplyResult::Noop,
            ApplyResult::SessionMissing | ApplyResult::Failed => NavigateApplyResult::Failed,
        })
    }

    fn commit_origin(&self, target: &Target) -> Result<(), String> {
        <Self as TogglePort>::save_previous(self, target)
    }

    fn observe_navigation(&self, message: &str) {
        <Self as TogglePort>::log(self, message);
    }
}

impl RecordPort for Runtime {
    fn acquire_record_lock(&self) -> Result<Box<dyn LockGuard + '_>, String> {
        <Self as TogglePort>::acquire_lock(self)
    }

    fn capture_record_target(&self) -> Result<Option<Target>, String> {
        <Self as TogglePort>::current(self)
    }

    fn save_record_target(&self, target: &Target) -> Result<(), String> {
        <Self as TogglePort>::save_previous(self, target)
    }

    fn observe_record(&self, message: &str) {
        <Self as TogglePort>::log(self, message);
    }
}

impl DiagnosePort for Runtime {
    fn timestamp(&self) -> String {
        now_seconds().to_string()
    }

    fn session_env(&self) -> Option<String> {
        std::env::var("ZELLIJ_SESSION_NAME").ok()
    }

    fn pane_env(&self) -> Option<String> {
        std::env::var("ZELLIJ_PANE_ID").ok()
    }

    fn current_session(&self) -> Option<String> {
        self.current_session()
    }

    fn pane_state(&self) -> Vec<Value> {
        self.visible_pane_state()
    }

    fn current_target(&self) -> Option<Target> {
        self.target_from_location()
    }

    fn current_location(&self) -> Option<Location> {
        self.focused_location()
    }
}

impl PluginSwitchPort for Runtime {
    fn zellij_available(&self) -> bool {
        command_available("zellij")
    }

    fn plugin_url(&self) -> String {
        self.plugin_url.clone()
    }

    fn plugin_grace_seconds(&self) -> f32 {
        self.plugin_grace_seconds
    }

    fn tab_state(&self, session: &str) -> Vec<Value> {
        self.tabs(session)
    }

    fn plugin_panes(&self) -> Vec<String> {
        self.visible_pane_state()
            .into_iter()
            .filter_map(|pane| {
                if pane.get("is_plugin").and_then(Value::as_bool) != Some(true) {
                    return None;
                }
                let title = pane.get("title").and_then(Value::as_str).unwrap_or("");
                if !title.contains("zellij-nav-switcher.wasm") {
                    return None;
                }
                pane.get("id")
                    .and_then(Value::as_u64)
                    .map(|id| format!("plugin_{id}"))
            })
            .collect()
    }

    fn close_pane(&self, pane_id: &str) {
        let _ =
            run_status(Command::new("zellij").args(["action", "close-pane", "--pane-id", pane_id]));
    }

    fn start_plugin(&self, plugin_url: &str, configuration: &str) -> Result<String, String> {
        run_capture(
            Command::new("zellij")
                .args(["action", "start-or-reload-plugin", plugin_url])
                .args(["--configuration", configuration]),
        )
    }

    fn sleep_seconds(&self, seconds: f32) {
        if seconds <= 0.0 {
            return;
        }
        std::thread::sleep(std::time::Duration::from_secs_f32(seconds));
    }
}

impl SidecarPort for Runtime {
    fn command_exists(&self, command: &str) -> bool {
        command_available(command)
    }

    fn session_exists(&self, session: &str) -> bool {
        self.session_exists(session)
    }

    fn tab_position(&self, session: &str, tab_id: u32) -> Option<u32> {
        let output = run_output(
            Command::new("zellij")
                .args(["--session", session, "action", "list-tabs"])
                .args(["--json", "--state", "--panes"]),
        );
        serde_json::from_str::<Vec<Value>>(&output)
            .ok()?
            .iter()
            .find(|tab| tab.get("tab_id").and_then(Value::as_u64) == Some(tab_id as u64))
            .and_then(|tab| tab.get("position").and_then(Value::as_u64))
            .map(|position| position as u32)
    }

    fn current_dir(&self) -> String {
        std::env::current_dir()
            .map(|path| path.to_string_lossy().to_string())
            .unwrap_or_else(|_| ".".to_string())
    }

    fn env_var(&self, name: &str) -> Option<String> {
        std::env::var(name).ok()
    }

    fn make_temp_path(&self, name: &str) -> Result<String, String> {
        let stamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|duration| duration.as_nanos())
            .unwrap_or(0);
        let path = std::env::temp_dir().join(format!("{name}.{}.{}", std::process::id(), stamp));
        File::create(&path).map_err(|err| err.to_string())?;
        Ok(path.to_string_lossy().to_string())
    }

    fn remove_file(&self, path: &str) {
        let _ = fs::remove_file(path);
    }

    fn runner_status(&self, path: &str) -> RunnerStatus {
        let Ok(status) = fs::read_to_string(path) else {
            return RunnerStatus::Missing;
        };
        let status = status.trim().to_string();
        if status == "ok" {
            return RunnerStatus::Ok;
        }
        RunnerStatus::Failed(status)
    }

    fn spawn_cli(&self, request: &LaunchRequest) -> Result<String, LaunchFailure> {
        let mut command = Command::new("wezterm");
        command.args(["cli", "spawn"]);
        if let Some(pane) = &request.wezterm_pane {
            command.args(["--pane-id", pane]);
        }
        command
            .args(["--cwd", &request.cwd])
            .args(["env", "-u", "ZELLIJ", "-u", "ZELLIJ_SESSION_NAME"])
            .args(["-u", "ZELLIJ_PANE_ID", "zellij", "attach", &request.session]);
        with_wezterm_socket(&mut command);
        run_launch(&mut command)
    }

    fn spawn_start(
        &self,
        request: &LaunchRequest,
        launch_log_file: &str,
    ) -> Result<String, LaunchFailure> {
        let log = File::create(launch_log_file).map_err(|err| LaunchFailure {
            status: 1,
            output: err.to_string(),
        })?;
        let err_log = log.try_clone().map_err(|err| LaunchFailure {
            status: 1,
            output: err.to_string(),
        })?;
        let child = Command::new("wezterm")
            .args(["start", "--always-new-process", "--cwd", &request.cwd, "--"])
            .args(["env", "-u", "ZELLIJ", "-u", "ZELLIJ_SESSION_NAME"])
            .args([
                "-u",
                "ZELLIJ_PANE_ID",
                "sh",
                "-c",
                "printf \"ok\\n\" > \"$1\"; exec zellij attach \"$2\"",
                "zellij-nav-attach",
                &request.status_file,
                &request.session,
            ])
            .stdout(Stdio::from(log))
            .stderr(Stdio::from(err_log))
            .spawn()
            .map_err(|err| LaunchFailure {
                status: 1,
                output: err.to_string(),
            })?;

        Ok(format!("wezterm_start_pid={}", child.id()))
    }

    fn go_to_tab(&self, session: &str, tab_id: u32) -> Result<(), String> {
        let tab = tab_id.to_string();
        if run_status(Command::new("zellij").args([
            "--session",
            session,
            "action",
            "go-to-tab-by-id",
            &tab,
        ])) {
            return Ok(());
        }
        Err(format!(
            "sidecar prepare failed action=go-to-tab-by-id session={session} tab={tab_id}"
        ))
    }

    fn focus_pane(&self, session: &str, pane_id: u32) -> Result<(), String> {
        let pane = format!("terminal_{pane_id}");
        if run_status(Command::new("zellij").args([
            "--session",
            session,
            "action",
            "focus-pane-id",
            &pane,
        ])) {
            return Ok(());
        }
        Err(format!(
            "sidecar prepare failed action=focus-pane-id session={session} pane={pane}"
        ))
    }

    fn count_session_clients(&self, session: &str) -> Result<u32, String> {
        let output = run_output(Command::new("zellij").args([
            "--session",
            session,
            "action",
            "list-clients",
        ]));
        Ok(output
            .lines()
            .skip(1)
            .filter(|line| !line.trim().is_empty())
            .count() as u32)
    }

    fn sleep_seconds(&self, seconds: f32) {
        if seconds <= 0.0 {
            return;
        }
        std::thread::sleep(std::time::Duration::from_secs_f32(seconds));
    }
}

impl PickerPort for Runtime {
    fn current_session(&self) -> Option<String> {
        self.current_session()
    }

    fn active_sessions(&self) -> Vec<String> {
        let output = run_output(Command::new("zellij").args(["list-sessions", "--no-formatting"]));
        output
            .lines()
            .filter(|line| !line.contains("EXITED"))
            .filter_map(|line| line.split_whitespace().next())
            .map(str::to_string)
            .collect()
    }

    fn tabs(&self) -> Vec<Value> {
        let output = run_output(Command::new("zellij").args(["action", "list-tabs", "--json"]));
        serde_json::from_str::<Vec<Value>>(&output).unwrap_or_default()
    }

    fn panes(&self, session: &str) -> Vec<Value> {
        self.panes(session)
    }

    fn env_var(&self, name: &str) -> Option<String> {
        std::env::var(name).ok()
    }

    fn record_current(&self, reason: &str) -> bool {
        crate::feature::record_current::run(self, reason).is_ok()
    }

    fn run_zellij_action(&self, action: PickerAction) -> bool {
        match action {
            PickerAction::NewPane => {
                run_status(Command::new("zellij").args(["action", "new-pane"]))
            }
            PickerAction::NewPaneRight => run_status(Command::new("zellij").args([
                "action",
                "new-pane",
                "--direction",
                "right",
            ])),
            PickerAction::NewPaneDown => run_status(Command::new("zellij").args([
                "action",
                "new-pane",
                "--direction",
                "down",
            ])),
            PickerAction::ToggleFullscreen => {
                run_status(Command::new("zellij").args(["action", "toggle-fullscreen"]))
            }
            PickerAction::ToggleFloatingPanes => {
                run_status(Command::new("zellij").args(["action", "toggle-floating-panes"]))
            }
            PickerAction::PreviousSwapLayout => {
                run_status(Command::new("zellij").args(["action", "previous-swap-layout"]))
            }
            PickerAction::NextSwapLayout => {
                run_status(Command::new("zellij").args(["action", "next-swap-layout"]))
            }
            PickerAction::Lock => {
                run_status(Command::new("zellij").args(["action", "switch-mode", "locked"]))
            }
            PickerAction::Detach => run_status(Command::new("zellij").args(["action", "detach"])),
        }
    }

    fn launch_session_manager(&self) -> bool {
        run_status(Command::new("zellij").args([
            "action",
            "launch-or-focus-plugin",
            "--floating",
            "--move-to-focused-tab",
            "zellij:session-manager",
        ]))
    }

    fn dump_screen(&self, session: &str, pane_id: &str) -> Option<String> {
        let output = Command::new("zellij")
            .args([
                "--session",
                session,
                "action",
                "dump-screen",
                "--pane-id",
                pane_id,
                "--ansi",
            ])
            .output()
            .ok()?;
        output
            .status
            .success()
            .then(|| String::from_utf8_lossy(&output.stdout).to_string())
    }

    fn select_candidate(
        &self,
        candidates: &str,
        preview_command: &str,
    ) -> Result<Option<String>, String> {
        let mut child = Command::new("fzf")
            .args(["--prompt=zellij> "])
            .arg(format!("--delimiter={}", '\t'))
            .args(["--with-nth=1"])
            .arg(format!("--preview={preview_command}"))
            .args(["--preview-window=right,65%,border-left,noinfo"])
            .args(["--bind=ctrl-/:toggle-preview"])
            .args(["--header=Enter: open  Ctrl-/: preview  Esc: cancel"])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .spawn()
            .map_err(|err| err.to_string())?;

        if let Some(stdin) = child.stdin.as_mut() {
            stdin
                .write_all(candidates.as_bytes())
                .map_err(|err| err.to_string())?;
        }

        let output = child.wait_with_output().map_err(|err| err.to_string())?;
        if !output.status.success() {
            return Ok(None);
        }
        let selection = String::from_utf8_lossy(&output.stdout).trim().to_string();
        Ok((!selection.is_empty()).then_some(selection))
    }

    fn navigate(&self, target_json: &str) -> u8 {
        crate::feature::navigate::run(self, target_json).unwrap_or(1)
    }

    fn current_pane_is_floating(&self) -> bool {
        current_pane_is_floating(self)
    }

    fn close_helper(&self, session: &str, pane_id: &str) -> u8 {
        crate::feature::helper::close(self, session, pane_id).unwrap_or(1)
    }

    fn log(&self, message: &str) {
        Runtime::log(self, message);
    }
}

impl HelperPort for Runtime {
    fn current_session(&self) -> Option<String> {
        self.current_session()
    }

    fn panes(&self, session: &str) -> Vec<Value> {
        self.panes(session)
    }

    fn focus_previous_pane(&self) -> bool {
        run_status(Command::new("zellij").args(["action", "focus-previous-pane"]))
    }

    fn close_pane(&self, session: &str, pane_id: &str) -> bool {
        run_status(Command::new("zellij").args([
            "--session",
            session,
            "action",
            "close-pane",
            "--pane-id",
            pane_id,
        ]))
    }

    fn sleep_millis(&self, millis: u64) {
        std::thread::sleep(std::time::Duration::from_millis(millis));
    }

    fn log(&self, message: &str) {
        Runtime::log(self, message);
    }
}

impl ContextTogglePort for Runtime {
    fn env_var(&self, name: &str) -> Option<String> {
        std::env::var(name).ok()
    }

    fn current_session(&self) -> Option<String> {
        self.current_session()
    }

    fn current_pane_is_floating(&self) -> bool {
        current_pane_is_floating(self)
    }

    fn focus_underlying(&self) -> u8 {
        crate::feature::helper::focus_underlying(self).unwrap_or(1)
    }

    fn toggle(&self) -> u8 {
        crate::feature::toggle::run(self).unwrap_or(1)
    }

    fn close_helper(&self, session: &str, pane_id: &str) -> u8 {
        crate::feature::helper::close(self, session, pane_id).unwrap_or(1)
    }

    fn log(&self, message: &str) {
        Runtime::log(self, message);
    }
}

impl Runtime {
    fn focus_with_plugin(&self, target: &Target) -> ApplyResult {
        self.log(&format!(
            "protected context detected route=plugin target={}",
            target.summary()
        ));
        if !self.plugin_switch_command.exists() {
            self.log("plugin navigation failed reason=missing-command");
            return ApplyResult::Failed;
        }

        let kind = kind_arg(target);
        let tab = opt_arg(target.tab_id);
        let pane = opt_arg(target.pane_id);
        if !run_status(
            Command::new(&self.plugin_switch_command)
                .arg(&target.session)
                .arg(kind)
                .arg(&tab)
                .arg(&pane),
        ) {
            self.log("plugin navigation failed reason=command-failed");
            return ApplyResult::Failed;
        }

        if self.confirm_or_accept(target) == ApplyResult::Moved {
            self.log(&format!(
                "plugin navigation confirmed session={} kind={} tab={} pane={}",
                target.session, kind, tab, pane
            ));
            return ApplyResult::Moved;
        }

        self.log(&format!(
            "plugin navigation failed reason=unconfirmed session={} kind={} tab={} pane={}",
            target.session, kind, tab, pane
        ));
        ApplyResult::Failed
    }

    fn focus_with_plugin_then_sidecar(&self, target: &Target) -> ApplyResult {
        self.log(&format!(
            "protected context detected route=plugin-sidecar target={}",
            target.summary()
        ));

        let plugin = self.focus_with_plugin(target);
        if plugin == ApplyResult::Moved {
            self.log("protected fallback skipped reason=plugin-moved");
            return ApplyResult::Moved;
        }

        self.log(&format!(
            "protected fallback starting from=plugin to=sidecar plugin_result={plugin:?} target={}",
            target.summary()
        ));
        let sidecar = self.focus_with_sidecar(target);
        if sidecar == ApplyResult::Moved {
            self.log("protected fallback completed route=sidecar");
            return ApplyResult::Moved;
        }

        self.log(&format!(
            "protected navigation failed route=plugin-sidecar plugin_result={plugin:?} sidecar_result={sidecar:?} target={}",
            target.summary()
        ));
        ApplyResult::Failed
    }

    fn focus_with_sidecar(&self, target: &Target) -> ApplyResult {
        self.log(&format!(
            "protected context detected route=sidecar target={}",
            target.summary()
        ));
        if !self.sidecar_command.exists() {
            self.log("sidecar navigation failed reason=missing-command");
            return ApplyResult::Failed;
        }

        let kind = kind_arg(target);
        let tab = opt_arg(target.tab_id);
        let pane = opt_arg(target.pane_id);
        match run_capture(
            Command::new(&self.sidecar_command)
                .arg(&target.session)
                .arg(kind)
                .arg(&tab)
                .arg(&pane),
        ) {
            Ok(output) => {
                let output = compact_output(&output);
                if !output.is_empty() {
                    self.log(&format!("sidecar navigation output {output}"));
                }
                self.log(&format!(
                    "sidecar navigation accepted session={}",
                    target.session
                ));
                ApplyResult::Moved
            }
            Err(output) => {
                let output = compact_output(&output);
                self.log(&format!(
                    "sidecar navigation failed reason=command-failed output={}",
                    non_empty_or_placeholder(&output)
                ));
                ApplyResult::Failed
            }
        }
    }
}

fn current_pane_is_floating(rt: &Runtime) -> bool {
    let Some(self_pane) = std::env::var("ZELLIJ_PANE_ID").ok() else {
        return false;
    };
    rt.visible_pane_state().iter().any(|pane| {
        pane.get("id")
            .and_then(Value::as_u64)
            .map(|id| id.to_string())
            == Some(self_pane.clone())
            && pane.get("is_floating").and_then(Value::as_bool) == Some(true)
    })
}

struct LeaseLock<'a> {
    rt: &'a Runtime,
}

impl<'a> LeaseLock<'a> {
    fn acquire(rt: &'a Runtime) -> Result<Self, String> {
        if fs::create_dir(&rt.lock_dir).is_ok() {
            write_lock_meta(rt);
            return Ok(Self { rt });
        }

        if !rt.lock_dir.exists() {
            return Err("lock acquisition failure".to_string());
        }

        if stale_lock(rt) {
            let _ = fs::remove_dir_all(&rt.lock_dir);
            if fs::create_dir(&rt.lock_dir).is_ok() {
                write_lock_meta(rt);
                rt.log("navigation lease lock reclaimed reason=stale");
                return Ok(Self { rt });
            }
        }

        rt.log("lock acquisition failure");
        Err("lock acquisition failure".to_string())
    }
}

impl LockGuard for LeaseLock<'_> {}

impl Drop for LeaseLock<'_> {
    fn drop(&mut self) {
        let _ = fs::remove_file(self.rt.lock_dir.join("created_at"));
        let _ = fs::remove_file(self.rt.lock_dir.join("owner_pid"));
        let _ = fs::remove_dir(&self.rt.lock_dir);
    }
}

fn write_lock_meta(rt: &Runtime) {
    let _ = fs::write(rt.lock_dir.join("created_at"), now_seconds().to_string());
    let _ = fs::write(
        rt.lock_dir.join("owner_pid"),
        std::process::id().to_string(),
    );
}

fn stale_lock(rt: &Runtime) -> bool {
    let owner = fs::read_to_string(rt.lock_dir.join("owner_pid"))
        .ok()
        .and_then(|value| value.trim().parse::<u32>().ok());
    if owner.is_some_and(|pid| !process_exists(pid)) {
        rt.log(&format!(
            "navigation lease lock reclaimed reason=dead-owner owner_pid={}",
            owner.unwrap_or_default()
        ));
        return true;
    }

    let ttl = std::env::var("ZELLIJ_NAV_LOCK_LEASE_TTL_SECONDS")
        .ok()
        .and_then(|value| value.parse::<u64>().ok())
        .unwrap_or(15);
    let created = fs::read_to_string(rt.lock_dir.join("created_at"))
        .ok()
        .and_then(|value| value.trim().parse::<u64>().ok());
    let expired = created.is_some_and(|created| now_seconds().saturating_sub(created) > ttl);
    if expired {
        rt.log("navigation lease lock reclaimed reason=ttl-expired");
    }
    expired
}

fn selectable_terminal(pane: &Value) -> bool {
    pane.get("is_plugin").and_then(Value::as_bool) == Some(false)
        && pane.get("is_selectable").and_then(Value::as_bool) == Some(true)
        && pane.get("exited").and_then(Value::as_bool) == Some(false)
}

fn pane_label(pane: &Value) -> String {
    let tab = pane
        .get("tab_name")
        .and_then(Value::as_str)
        .unwrap_or("Tab");
    let title = ["title", "pane_command", "terminal_command", "pane_cwd"]
        .iter()
        .find_map(|key| pane.get(*key).and_then(Value::as_str))
        .unwrap_or("pane");
    format!("{tab} / {title}")
}

fn pane_is_protected(pane: &Value, pattern: &str) -> bool {
    let text = ["pane_command", "terminal_command", "title"]
        .iter()
        .filter_map(|key| pane.get(*key).and_then(Value::as_str))
        .collect::<Vec<_>>()
        .join(" ");
    protected_match(&text, pattern)
}

fn rotate_log_if_needed(log_file: &Path) {
    let max_bytes = std::env::var("ZELLIJ_NAV_LOG_ROTATE_BYTES")
        .ok()
        .and_then(|value| value.parse::<u64>().ok())
        .unwrap_or(1024 * 1024);
    if max_bytes == 0 {
        return;
    }
    let rotate_files = std::env::var("ZELLIJ_NAV_LOG_ROTATE_FILES")
        .ok()
        .and_then(|value| value.parse::<u8>().ok())
        .unwrap_or(3);
    if rotate_files == 0 {
        return;
    }
    let Ok(metadata) = fs::metadata(log_file) else {
        return;
    };
    if metadata.len() < max_bytes {
        return;
    }

    for index in (1..=rotate_files).rev() {
        let source = rotated_log_path(log_file, index);
        if index == rotate_files {
            let _ = fs::remove_file(source);
            continue;
        }
        let target = rotated_log_path(log_file, index + 1);
        let _ = fs::rename(source, target);
    }
    let _ = fs::rename(log_file, rotated_log_path(log_file, 1));
}

fn rotated_log_path(log_file: &Path, index: u8) -> PathBuf {
    let mut path = log_file.as_os_str().to_os_string();
    path.push(format!(".{index}"));
    PathBuf::from(path)
}

fn protected_match(text: &str, pattern: &str) -> bool {
    Command::new("sh")
        .arg("-c")
        .arg("printf '%s\n' \"$ZELLIJ_NAV_TEXT\" | grep -E \"$ZELLIJ_NAV_PATTERN\" >/dev/null 2>&1")
        .env("ZELLIJ_NAV_TEXT", text)
        .env("ZELLIJ_NAV_PATTERN", pattern)
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

fn kind_arg(target: &Target) -> &'static str {
    match target.kind {
        TargetKind::Session => "session",
        TargetKind::Tab => "tab",
        TargetKind::Pane => "pane",
    }
}

fn opt_arg(value: Option<u32>) -> String {
    value.map(|id| id.to_string()).unwrap_or_default()
}

fn run_output(command: &mut Command) -> String {
    command
        .output()
        .ok()
        .filter(|output| output.status.success())
        .map(|output| String::from_utf8_lossy(&output.stdout).to_string())
        .unwrap_or_default()
}

fn run_status(command: &mut Command) -> bool {
    command
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

fn run_capture(command: &mut Command) -> Result<String, String> {
    let output = command.output().map_err(|err| err.to_string())?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    let combined = format!("{stdout}{stderr}");

    if output.status.success() {
        return Ok(combined);
    }
    Err(combined)
}

fn compact_output(output: &str) -> String {
    output.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn non_empty_or_placeholder(value: &str) -> &str {
    if value.is_empty() {
        return "<empty>";
    }
    value
}

fn run_launch(command: &mut Command) -> Result<String, LaunchFailure> {
    let output = command.output().map_err(|err| LaunchFailure {
        status: 1,
        output: err.to_string(),
    })?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    let combined = format!("{stdout}{stderr}");

    if output.status.success() {
        return Ok(combined);
    }

    Err(LaunchFailure {
        status: output.status.code().unwrap_or(1) as u8,
        output: combined,
    })
}

fn with_wezterm_socket(command: &mut Command) {
    let current_socket = std::env::var("WEZTERM_UNIX_SOCKET").ok();
    if current_socket.as_deref().map(is_socket) == Some(true) {
        return;
    }

    let home = std::env::var("HOME").unwrap_or_else(|_| ".".to_string());
    let default_socket = std::env::var("ZELLIJ_NAV_WEZTERM_DEFAULT_SOCKET")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            std::env::var("XDG_DATA_HOME")
                .map(PathBuf::from)
                .unwrap_or_else(|_| PathBuf::from(home).join(".local/share"))
                .join("wezterm/default-org.wezfurlong.wezterm")
        });

    if is_socket(&default_socket) {
        command.env("WEZTERM_UNIX_SOCKET", default_socket);
    }
}

#[cfg(unix)]
fn is_socket(path: impl AsRef<Path>) -> bool {
    fs::metadata(path)
        .map(|metadata| metadata.file_type().is_socket())
        .unwrap_or(false)
}

#[cfg(not(unix))]
fn is_socket(_path: impl AsRef<Path>) -> bool {
    false
}

fn command_available(command: &str) -> bool {
    Command::new("sh")
        .arg("-c")
        .arg("command -v \"$ZELLIJ_NAV_COMMAND_CHECK\" >/dev/null 2>&1")
        .env("ZELLIJ_NAV_COMMAND_CHECK", command)
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

fn process_exists(pid: u32) -> bool {
    Command::new("kill")
        .arg("-0")
        .arg(pid.to_string())
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

fn now_seconds() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or(0)
}

fn chrono_like_stamp() -> String {
    now_seconds().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn protected_match_respects_custom_regex() {
        assert!(protected_match("vim src/main.rs", "vim"));
        assert!(!protected_match("bash", "vim"));
    }
}
