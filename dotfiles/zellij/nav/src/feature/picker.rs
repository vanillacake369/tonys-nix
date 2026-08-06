use crate::domain::{Target, TargetKind};
use serde_json::Value;

pub trait PickerPort {
    fn current_session(&self) -> Option<String>;
    fn active_sessions(&self) -> Vec<String>;
    fn tabs(&self) -> Vec<Value>;
    fn panes(&self, session: &str) -> Vec<Value>;
    fn env_var(&self, name: &str) -> Option<String>;
    fn record_current(&self, reason: &str) -> bool;
    fn run_zellij_action(&self, action: PickerAction) -> bool;
    fn launch_session_manager(&self) -> bool;
    fn dump_screen(&self, session: &str, pane_id: &str) -> Option<String>;
    fn select_candidate(
        &self,
        candidates: &str,
        preview_command: &str,
    ) -> Result<Option<String>, String>;
    fn navigate(&self, target_json: &str) -> u8;
    fn current_pane_is_floating(&self) -> bool;
    fn close_helper(&self, session: &str, pane_id: &str) -> u8;
    fn log(&self, message: &str);
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum PickerMode {
    Commands,
    Sessions,
    Tabs,
    Panes,
    All,
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct Candidate {
    display: String,
    kind: String,
    session: String,
    tab_id: String,
    pane_id: String,
    command_id: String,
    group: String,
    title: String,
    command: String,
    cwd: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum PickerAction {
    NewPane,
    NewPaneRight,
    NewPaneDown,
    ToggleFullscreen,
    ToggleFloatingPanes,
    PreviousSwapLayout,
    NextSwapLayout,
    Lock,
    Detach,
}

pub fn candidates(port: &impl PickerPort, mode: &str) -> Result<String, String> {
    let mode = PickerMode::from_arg(mode);
    let mut candidates = Vec::new();

    if mode.includes_commands() {
        candidates.extend(command_candidates());
    }
    if mode.includes_sessions() {
        candidates.extend(session_candidates(port)?);
    }
    if mode.includes_tabs() {
        candidates.extend(tab_candidates(port)?);
    }
    if mode.includes_panes() {
        candidates.extend(pane_candidates(port)?);
    }

    Ok(candidates
        .into_iter()
        .map(|candidate| candidate.to_tsv())
        .collect::<Vec<_>>()
        .join("\n")
        + "\n")
}

pub fn target_from_selection(selection: &str) -> Result<String, String> {
    let fields = selection.split('\t').collect::<Vec<_>>();
    if fields.len() < 5 {
        return Err("invalid picker selection".to_string());
    }

    let kind = match fields[1] {
        "session" => TargetKind::Session,
        "tab" => TargetKind::Tab,
        "pane" => TargetKind::Pane,
        other => return Err(format!("unsupported picker target kind: {other}")),
    };
    let target = Target {
        kind,
        session: value_field(fields[2]),
        tab_id: id_field(fields[3])?,
        pane_id: id_field(fields[4])?,
        label: value_field(fields[0]),
    };

    if !target.valid() {
        return Err(format!(
            "invalid picker target: {}",
            target.validation_reason()
        ));
    }
    serde_json::to_string(&target).map_err(|err| err.to_string())
}

pub fn command(port: &impl PickerPort, command_id: &str) -> Result<u8, String> {
    let ok = match command_id {
        "new-pane" => port.run_zellij_action(PickerAction::NewPane),
        "new-pane-right" => port.run_zellij_action(PickerAction::NewPaneRight),
        "new-pane-down" => port.run_zellij_action(PickerAction::NewPaneDown),
        "toggle-fullscreen" => port.run_zellij_action(PickerAction::ToggleFullscreen),
        "toggle-floating-panes" => port.run_zellij_action(PickerAction::ToggleFloatingPanes),
        "previous-swap-layout" => port.run_zellij_action(PickerAction::PreviousSwapLayout),
        "next-swap-layout" => port.run_zellij_action(PickerAction::NextSwapLayout),
        "lock" => port.run_zellij_action(PickerAction::Lock),
        "detach" => port.run_zellij_action(PickerAction::Detach),
        "session-manager" => {
            let _ = port.record_current("session-manager");
            port.launch_session_manager()
        }
        _ => {
            port.log(&format!("unknown command command_id={command_id}"));
            return Ok(1);
        }
    };

    if ok {
        port.log(&format!("command executed command_id={command_id}"));
        return Ok(0);
    }

    port.log(&format!("command failed command_id={command_id}"));
    Ok(1)
}

pub fn preview(
    port: &impl PickerPort,
    kind: &str,
    session: &str,
    tab_id: &str,
    pane_id: &str,
    command_id: &str,
    label: &str,
) -> String {
    match kind {
        "command" => command_preview(command_id, label),
        "pane" | "tab" | "session" => target_preview(port, kind, session, tab_id, pane_id),
        "" => preview_error("Unsupported candidate type: unknown"),
        other => preview_error(&format!("Unsupported candidate type: {other}")),
    }
}

pub fn run(port: &impl PickerPort, mode: &str, preview_program: &str) -> Result<u8, String> {
    let helper_session = helper_session(port);
    let status = run_inner(port, mode, preview_program);
    // NOTE: fzf preview child도 helper env를 상속한다. picker 본체가 끝난 뒤에만
    // close를 시도해야 preview 이동 중 floating helper를 닫는 race를 피한다.
    close_helper(port, helper_session);
    status
}

fn run_inner(port: &impl PickerPort, mode: &str, preview_program: &str) -> Result<u8, String> {
    let input = candidates(port, mode)?;
    let preview_command = format!(
        "{} --render-preview {{2}} {{3}} {{4}} {{5}} {{6}} {{8}}",
        shell_quote(preview_program)
    );
    let Some(selection) = port.select_candidate(&input, &preview_command)? else {
        port.log(&format!("picker cancelled mode={mode}"));
        return Ok(0);
    };

    let fields = selection.split('\t').collect::<Vec<_>>();
    let kind = fields.get(1).copied().unwrap_or_default();
    if kind == "command" {
        return command(port, fields.get(5).copied().unwrap_or_default());
    }

    let target_json = target_from_selection(&selection)?;
    let status = port.navigate(&target_json);
    log_navigation(port, status, &target_json);
    Ok(0)
}

fn helper_session(port: &impl PickerPort) -> Option<String> {
    if port.env_var("ZELLIJ_NAV_HELPER").as_deref() == Some("1") {
        return port.current_session();
    }
    if port.current_pane_is_floating() {
        port.log("picker helper inferred reason=legacy-floating-pane");
        return port.current_session();
    }
    None
}

fn close_helper(port: &impl PickerPort, session: Option<String>) {
    let Some(session) = session else {
        return;
    };
    let pane_id = port.env_var("ZELLIJ_PANE_ID").unwrap_or_default();
    let _ = port.close_helper(&session, &pane_id);
}

impl PickerMode {
    fn from_arg(mode: &str) -> Self {
        match mode {
            "--commands" => Self::Commands,
            "--sessions" => Self::Sessions,
            "--tabs" => Self::Tabs,
            "--panes" => Self::Panes,
            _ => Self::All,
        }
    }

    fn includes_commands(&self) -> bool {
        matches!(self, Self::Commands | Self::All)
    }

    fn includes_sessions(&self) -> bool {
        matches!(self, Self::Sessions | Self::All)
    }

    fn includes_tabs(&self) -> bool {
        matches!(self, Self::Tabs | Self::All)
    }

    fn includes_panes(&self) -> bool {
        matches!(self, Self::Panes | Self::All)
    }
}

impl Candidate {
    fn to_tsv(&self) -> String {
        [
            self.display.as_str(),
            self.kind.as_str(),
            self.session.as_str(),
            self.tab_id.as_str(),
            self.pane_id.as_str(),
            self.command_id.as_str(),
            self.group.as_str(),
            self.title.as_str(),
            self.command.as_str(),
            self.cwd.as_str(),
        ]
        .join("\t")
    }
}

fn command_candidates() -> Vec<Candidate> {
    [
        ("New pane", "new-pane", "Pane"),
        ("New pane right", "new-pane-right", "Pane"),
        ("New pane down", "new-pane-down", "Pane"),
        ("Toggle fullscreen", "toggle-fullscreen", "Pane"),
        ("Toggle floating panes", "toggle-floating-panes", "Pane"),
        ("Previous swap layout", "previous-swap-layout", "Layout"),
        ("Next swap layout", "next-swap-layout", "Layout"),
        ("Session manager", "session-manager", "Session"),
        ("Lock", "lock", "System"),
        ("Detach", "detach", "System"),
    ]
    .into_iter()
    .map(|(label, id, group)| Candidate {
        display: format!("[CMD] {label}"),
        kind: "command".to_string(),
        session: "-".to_string(),
        tab_id: "-".to_string(),
        pane_id: "-".to_string(),
        command_id: id.to_string(),
        group: group.to_string(),
        title: label.to_string(),
        command: "-".to_string(),
        cwd: "-".to_string(),
    })
    .collect()
}

fn target_preview(
    port: &impl PickerPort,
    kind: &str,
    session: &str,
    tab_id: &str,
    pane_id: &str,
) -> String {
    if session.is_empty() || session == "-" {
        return preview_error("No session is associated with this candidate.");
    }

    let Some(pane_id) = resolve_preview_pane(port, kind, session, tab_id, pane_id) else {
        return preview_error("No selectable terminal pane was found.");
    };
    let Some(frame) = port.dump_screen(session, &pane_id) else {
        return preview_error(&format!(
            "Unable to capture pane {pane_id} from session {session}."
        ));
    };

    format!(
        "\u{1b}[H\u{1b}[2J{}{}",
        preview_header(port, kind, session, tab_id, &pane_id),
        frame
    )
}

fn command_preview(command_id: &str, label: &str) -> String {
    let command_id = if command_id.is_empty() {
        "-"
    } else {
        command_id
    };
    let label = if label.is_empty() { "Command" } else { label };

    format!(
        "\u{1b}[H\u{1b}[2J\u{1b}[1m{label}\u{1b}[0m\n\nAction ID: {command_id}\n\nPress Enter to execute this Zellij action.\n"
    )
}

fn preview_error(message: &str) -> String {
    format!("\u{1b}[H\u{1b}[2J\u{1b}[1mPreview unavailable\u{1b}[0m\n\n{message}\n")
}

fn preview_header(
    port: &impl PickerPort,
    kind: &str,
    session: &str,
    tab_id: &str,
    pane_id: &str,
) -> String {
    let columns = port
        .env_var("FZF_PREVIEW_COLUMNS")
        .and_then(|value| value.parse::<usize>().ok())
        .unwrap_or(80);

    format!(
        "\u{1b}[2mtype={kind}  session={session}  tab={tab_id}  pane={pane_id}\n\u{1b}[0m{}\n",
        "-".repeat(columns)
    )
}

fn resolve_preview_pane(
    port: &impl PickerPort,
    kind: &str,
    session: &str,
    tab_id: &str,
    pane_id: &str,
) -> Option<String> {
    match kind {
        "pane" if !pane_id.is_empty() && pane_id != "-" => Some(pane_id.to_string()),
        "tab" => selectable_preview_pane(port, session, Some(tab_id)),
        "session" => selectable_preview_pane(port, session, None),
        _ => None,
    }
}

fn selectable_preview_pane(
    port: &impl PickerPort,
    session: &str,
    tab_id: Option<&str>,
) -> Option<String> {
    // PERF: preview는 selection 이동마다 호출된다. 여기서는 전체 pane list를 한 번만
    // 순회하고 focused pane 우선순위만 후처리해 fzf 입력 반응성을 유지한다.
    let panes = port
        .panes(session)
        .into_iter()
        .filter(selectable_terminal)
        .filter(|pane| {
            tab_id.is_none_or(|tab_id| {
                pane.get("tab_id")
                    .and_then(Value::as_u64)
                    .map(|id| id.to_string())
                    == Some(tab_id.to_string())
            })
        })
        .collect::<Vec<_>>();

    panes
        .iter()
        .find(|pane| pane.get("is_focused").and_then(Value::as_bool) == Some(true))
        .or_else(|| panes.first())
        .and_then(|pane| pane.get("id").and_then(Value::as_u64))
        .map(|id| id.to_string())
}

fn session_candidates(port: &impl PickerPort) -> Result<Vec<Candidate>, String> {
    let current = port
        .current_session()
        .ok_or_else(|| "missing current session".to_string())?;
    Ok(port
        .active_sessions()
        .into_iter()
        .filter(|session| !session.is_empty())
        .map(|session| {
            let suffix = if session == current { " *" } else { "" };
            Candidate {
                display: format!("[SESSION] {session}{suffix}"),
                kind: "session".to_string(),
                session: session.clone(),
                tab_id: "-".to_string(),
                pane_id: "-".to_string(),
                command_id: "-".to_string(),
                group: session.clone(),
                title: session,
                command: "-".to_string(),
                cwd: "-".to_string(),
            }
        })
        .collect())
}

fn tab_candidates(port: &impl PickerPort) -> Result<Vec<Candidate>, String> {
    let session = port
        .current_session()
        .ok_or_else(|| "missing current session".to_string())?;
    Ok(port
        .tabs()
        .into_iter()
        .filter_map(|tab| {
            let name = tab.get("name").and_then(Value::as_str)?;
            let tab_id = tab.get("tab_id").and_then(Value::as_u64)?;
            Some(Candidate {
                display: format!("[TAB] {name}"),
                kind: "tab".to_string(),
                session: session.clone(),
                tab_id: tab_id.to_string(),
                pane_id: "-".to_string(),
                command_id: "-".to_string(),
                group: name.to_string(),
                title: name.to_string(),
                command: "-".to_string(),
                cwd: "-".to_string(),
            })
        })
        .collect())
}

fn pane_candidates(port: &impl PickerPort) -> Result<Vec<Candidate>, String> {
    let session = port
        .current_session()
        .ok_or_else(|| "missing current session".to_string())?;
    let current_pane = port.env_var("ZELLIJ_PANE_ID").map(normalize_pane_id);

    Ok(port
        .panes(&session)
        .into_iter()
        .filter(selectable_terminal)
        .filter_map(|pane| {
            let id = pane.get("id")?.as_u64()?.to_string();
            if Some(normalize_pane_id(id.clone())) == current_pane {
                return None;
            }
            let tab_id = pane.get("tab_id")?.as_u64()?.to_string();
            let tab = text_field(
                pane.get("tab_name")
                    .and_then(Value::as_str)
                    .map(str::to_string)
                    .unwrap_or_else(|| format!("Tab {tab_id}")),
            );
            let title = text_field(first_text(
                &pane,
                &["title", "pane_command", "terminal_command", "pane_cwd"],
            ));
            let command = text_field(first_text(&pane, &["pane_command", "terminal_command"]));
            let cwd = text_field(first_text(&pane, &["pane_cwd"]));

            Some(Candidate {
                display: format!("[PANE] {tab} / {title}"),
                kind: "pane".to_string(),
                session: session.clone(),
                tab_id,
                pane_id: id,
                command_id: "-".to_string(),
                group: tab,
                title,
                command,
                cwd,
            })
        })
        .collect())
}

fn selectable_terminal(pane: &Value) -> bool {
    pane.get("is_selectable").and_then(Value::as_bool) == Some(true)
        && pane.get("is_plugin").and_then(Value::as_bool) == Some(false)
        && pane.get("exited").and_then(Value::as_bool) == Some(false)
}

fn first_text(pane: &Value, keys: &[&str]) -> String {
    keys.iter()
        .find_map(|key| pane.get(*key).and_then(Value::as_str))
        .unwrap_or_default()
        .to_string()
}

fn text_field(value: String) -> String {
    if value.is_empty() {
        return "-".to_string();
    }
    value
}

fn value_field(value: &str) -> String {
    if value == "-" {
        return String::new();
    }
    value.to_string()
}

fn id_field(value: &str) -> Result<Option<u32>, String> {
    if value == "-" || value.is_empty() {
        return Ok(None);
    }
    value
        .parse::<u32>()
        .map(Some)
        .map_err(|err| err.to_string())
}

fn normalize_pane_id(value: String) -> String {
    value
        .strip_prefix("terminal_")
        .unwrap_or(&value)
        .to_string()
}

fn log_navigation(port: &impl PickerPort, status: u8, target_json: &str) {
    let target = serde_json::from_str::<Target>(target_json)
        .map(|target| target.summary())
        .unwrap_or_else(|_| r#"{"kind":"invalid"}"#.to_string());
    match status {
        0 => port.log(&format!("picker navigation completed target={target}")),
        3 => port.log(&format!("picker navigation no-op target={target}")),
        4 => port.log(&format!(
            "picker navigation partial status=history-commit-failed moved_to={target} previous_history_preserved=true"
        )),
        _ => port.log(&format!(
            "picker navigation failed status={status} target={target}"
        )),
    }
}

fn shell_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}

#[cfg(test)]
mod tests {
    use super::*;

    struct FakePort;

    impl PickerPort for FakePort {
        fn current_session(&self) -> Option<String> {
            Some("current".to_string())
        }

        fn active_sessions(&self) -> Vec<String> {
            vec!["current".to_string(), "target".to_string()]
        }

        fn tabs(&self) -> Vec<Value> {
            serde_json::json!([
                {"name": "work", "tab_id": 0},
                {"name": "ops", "tab_id": 1}
            ])
            .as_array()
            .unwrap()
            .clone()
        }

        fn panes(&self, _session: &str) -> Vec<Value> {
            serde_json::json!([
                {
                    "id": 1,
                    "tab_id": 0,
                    "tab_name": "work",
                    "title": "editor",
                    "pane_command": "nvim",
                    "pane_cwd": "/repo",
                    "is_selectable": true,
                    "is_plugin": false,
                    "exited": false
                },
                {
                    "id": 2,
                    "tab_id": 0,
                    "tab_name": "work",
                    "title": "plugin",
                    "is_selectable": true,
                    "is_plugin": true,
                    "exited": false
                }
            ])
            .as_array()
            .unwrap()
            .clone()
        }

        fn env_var(&self, name: &str) -> Option<String> {
            (name == "ZELLIJ_PANE_ID").then(|| "1".to_string())
        }

        fn record_current(&self, _reason: &str) -> bool {
            true
        }

        fn run_zellij_action(&self, _action: PickerAction) -> bool {
            true
        }

        fn launch_session_manager(&self) -> bool {
            true
        }

        fn dump_screen(&self, session: &str, pane_id: &str) -> Option<String> {
            Some(format!("preview for {session}/{pane_id}\n"))
        }

        fn select_candidate(
            &self,
            _candidates: &str,
            _preview_command: &str,
        ) -> Result<Option<String>, String> {
            Ok(Some(
                "[SESSION] target\tsession\ttarget\t-\t-\t-\ttarget\ttarget\t-\t-".to_string(),
            ))
        }

        fn navigate(&self, _target_json: &str) -> u8 {
            0
        }

        fn current_pane_is_floating(&self) -> bool {
            false
        }

        fn close_helper(&self, session: &str, pane_id: &str) -> u8 {
            self.log(&format!("close:{session}:{pane_id}"));
            0
        }

        fn log(&self, _message: &str) {}
    }

    #[test]
    fn session_candidates_mark_current_session() {
        let output = candidates(&FakePort, "--sessions").unwrap();

        assert!(output.contains("[SESSION] current *\tsession\tcurrent"));
        assert!(output.contains("[SESSION] target\tsession\ttarget"));
    }

    #[test]
    fn pane_candidates_skip_current_and_plugins() {
        let output = candidates(&FakePort, "--panes").unwrap();

        assert!(!output.contains("editor"));
        assert!(!output.contains("plugin"));
    }

    #[test]
    fn selection_to_target_matches_navigation_contract() {
        let selection = "[SESSION] target\tsession\ttarget\t-\t-\t-\ttarget\ttarget\t-\t-";
        let target = target_from_selection(selection).unwrap();

        assert_eq!(
            target,
            r#"{"kind":"session","session":"target","tab_id":null,"pane_id":null,"label":"[SESSION] target"}"#
        );
    }

    #[test]
    fn command_executes_known_action_and_logs() {
        assert_eq!(command(&FakePort, "new-pane").unwrap(), 0);
        assert_eq!(command(&FakePort, "missing").unwrap(), 1);
    }

    #[test]
    fn preview_resolves_tab_to_selectable_pane() {
        let output = preview(&FakePort, "tab", "current", "0", "-", "-", "work");

        assert!(output.contains("type=tab  session=current  tab=0  pane=1"));
        assert!(output.contains("preview for current/1"));
    }

    #[test]
    fn run_selects_candidate_and_navigates() {
        assert_eq!(
            run(&FakePort, "--sessions", "zellij-pane-picker").unwrap(),
            0
        );
    }
}
