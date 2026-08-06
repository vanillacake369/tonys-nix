use serde_json::Value;

pub const OK: u8 = 0;
pub const FAILED: u8 = 1;
pub const USAGE: u8 = 64;
pub const NOT_FOUND: u8 = 66;
pub const TOOL_MISSING: u8 = 127;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum SwitchKind {
    Session,
    Tab,
    Pane,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SwitchTarget {
    pub session: String,
    pub kind: SwitchKind,
    pub tab_id: Option<u32>,
    pub pane_id: Option<u32>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SwitchExit {
    pub code: u8,
    pub stdout: String,
    pub stderr: String,
}

pub trait PluginSwitchPort {
    fn zellij_available(&self) -> bool;
    fn plugin_url(&self) -> String;
    fn plugin_grace_seconds(&self) -> f32;
    fn tab_state(&self, session: &str) -> Vec<Value>;
    fn plugin_panes(&self) -> Vec<String>;
    fn close_pane(&self, pane_id: &str);
    fn start_plugin(&self, plugin_url: &str, configuration: &str) -> Result<String, String>;
    fn sleep_seconds(&self, seconds: f32);
}

pub fn run<P>(port: &P, target: SwitchTarget) -> Result<SwitchExit, String>
where
    P: PluginSwitchPort,
{
    if !port.zellij_available() {
        return Ok(err(TOOL_MISSING, "zellij not found"));
    }

    let tab_position = match resolve_tab_position(port, &target) {
        Ok(position) => position,
        Err(exit) => return Ok(exit),
    };
    let tab_position = match tab_position {
        Some(position) => position.to_string(),
        None => String::new(),
    };
    let pane_id = target.pane_id.map(|id| id.to_string()).unwrap_or_default();
    let configuration = format!(
        "session={},kind={},tab_id={},pane_id={}",
        target.session,
        kind_name(&target.kind),
        tab_position,
        pane_id
    );

    match port.start_plugin(&port.plugin_url(), &configuration) {
        Ok(output) => {
            port.sleep_seconds(port.plugin_grace_seconds());
            close_plugin_panes(port);
            Ok(SwitchExit {
                code: OK,
                stdout: format!(
                    "accepted:start-or-reload-plugin output={}\n",
                    one_line(&output, 160)
                ),
                stderr: String::new(),
            })
        }
        Err(output) => {
            close_plugin_panes(port);
            Ok(SwitchExit {
                code: FAILED,
                stdout: String::new(),
                stderr: format!("{output}\n"),
            })
        }
    }
}

pub fn target_from_args(
    session: String,
    kind: String,
    tab_id: String,
    pane_id: String,
) -> Result<SwitchTarget, SwitchExit> {
    if session.is_empty() {
        return Err(err(USAGE, "missing session"));
    }

    let kind = match kind.as_str() {
        "session" => SwitchKind::Session,
        "tab" => SwitchKind::Tab,
        "pane" => SwitchKind::Pane,
        other => return Err(err(USAGE, &format!("unsupported kind: {other}"))),
    };
    let tab_id = parse_optional_u32(&tab_id, "tab")?;
    let pane_id = parse_optional_u32(&pane_id, "pane")?;

    if matches!(kind, SwitchKind::Tab | SwitchKind::Pane) && tab_id.is_none() {
        return Err(err(USAGE, "missing tab id"));
    }
    if matches!(kind, SwitchKind::Pane) && pane_id.is_none() {
        return Err(err(USAGE, "missing pane id"));
    }

    Ok(SwitchTarget {
        session,
        kind,
        tab_id,
        pane_id,
    })
}

fn resolve_tab_position<P>(port: &P, target: &SwitchTarget) -> Result<Option<u32>, SwitchExit>
where
    P: PluginSwitchPort,
{
    if matches!(target.kind, SwitchKind::Session) {
        return Ok(None);
    }

    let Some(tab_id) = target.tab_id else {
        return Ok(None);
    };
    let position = port.tab_state(&target.session).into_iter().find_map(|tab| {
        let found = tab.get("tab_id").and_then(Value::as_u64)? as u32;
        if found != tab_id {
            return None;
        }
        tab.get("position")
            .and_then(Value::as_u64)
            .map(|id| id as u32)
    });

    match position {
        Some(position) => Ok(Some(position)),
        None => Err(err(
            NOT_FOUND,
            &format!("tab not found: session={} tab={}", target.session, tab_id),
        )),
    }
}

fn close_plugin_panes<P>(port: &P)
where
    P: PluginSwitchPort,
{
    for pane in port.plugin_panes() {
        port.close_pane(&pane);
    }
}

fn parse_optional_u32(value: &str, name: &str) -> Result<Option<u32>, SwitchExit> {
    if value.is_empty() || value == "null" {
        return Ok(None);
    }
    value
        .parse::<u32>()
        .map(Some)
        .map_err(|_| err(USAGE, &format!("invalid {name} id: {value}")))
}

fn kind_name(kind: &SwitchKind) -> &'static str {
    match kind {
        SwitchKind::Session => "session",
        SwitchKind::Tab => "tab",
        SwitchKind::Pane => "pane",
    }
}

fn err(code: u8, message: &str) -> SwitchExit {
    SwitchExit {
        code,
        stdout: String::new(),
        stderr: format!("{message}\n"),
    }
}

fn one_line(text: &str, max_chars: usize) -> String {
    text.replace('\n', " ").chars().take(max_chars).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    struct FakePort {
        available: bool,
        tabs: Vec<Value>,
        panes: Vec<String>,
        started: RefCell<Vec<String>>,
        closed: RefCell<Vec<String>>,
    }

    impl PluginSwitchPort for FakePort {
        fn zellij_available(&self) -> bool {
            self.available
        }

        fn plugin_url(&self) -> String {
            "file:/plugin.wasm".to_string()
        }

        fn plugin_grace_seconds(&self) -> f32 {
            0.0
        }

        fn tab_state(&self, _session: &str) -> Vec<Value> {
            self.tabs.clone()
        }

        fn plugin_panes(&self) -> Vec<String> {
            self.panes.clone()
        }

        fn close_pane(&self, pane_id: &str) {
            self.closed.borrow_mut().push(pane_id.to_string());
        }

        fn start_plugin(&self, _plugin_url: &str, configuration: &str) -> Result<String, String> {
            self.started.borrow_mut().push(configuration.to_string());
            Ok("plugin_55".to_string())
        }

        fn sleep_seconds(&self, _seconds: f32) {}
    }

    #[test]
    fn tab_target_uses_tab_position_for_plugin_configuration() {
        let port = FakePort {
            available: true,
            tabs: vec![serde_json::json!({"tab_id": 9, "position": 1})],
            panes: Vec::new(),
            started: RefCell::new(Vec::new()),
            closed: RefCell::new(Vec::new()),
        };
        let target =
            target_from_args("target".into(), "tab".into(), "9".into(), "".into()).unwrap();

        let exit = run(&port, target).unwrap();

        assert_eq!(exit.code, OK);
        assert_eq!(
            port.started.borrow().as_slice(),
            &["session=target,kind=tab,tab_id=1,pane_id="]
        );
    }

    #[test]
    fn closes_existing_switcher_plugin_panes_after_launch() {
        let port = FakePort {
            available: true,
            tabs: Vec::new(),
            panes: vec!["plugin_55".to_string()],
            started: RefCell::new(Vec::new()),
            closed: RefCell::new(Vec::new()),
        };
        let target =
            target_from_args("target".into(), "session".into(), "".into(), "".into()).unwrap();

        assert_eq!(run(&port, target).unwrap().code, OK);
        assert_eq!(port.closed.borrow().as_slice(), &["plugin_55"]);
    }

    #[test]
    fn rejects_missing_pane_id_before_effects() {
        let exit =
            target_from_args("target".into(), "pane".into(), "1".into(), "".into()).unwrap_err();

        assert_eq!(exit.code, USAGE);
        assert!(exit.stderr.contains("missing pane id"));
    }

    #[test]
    fn missing_tab_reports_bash_compatible_not_found() {
        let port = FakePort {
            available: true,
            tabs: Vec::new(),
            panes: Vec::new(),
            started: RefCell::new(Vec::new()),
            closed: RefCell::new(Vec::new()),
        };
        let target =
            target_from_args("target".into(), "tab".into(), "9".into(), "".into()).unwrap();

        let exit = run(&port, target).unwrap();

        assert_eq!(exit.code, NOT_FOUND);
        assert!(exit.stderr.contains("tab not found: session=target tab=9"));
        assert!(port.started.borrow().is_empty());
    }
}
