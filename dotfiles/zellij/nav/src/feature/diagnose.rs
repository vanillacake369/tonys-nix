use crate::domain::{Location, Target};
use serde_json::Value;

pub trait DiagnosePort {
    fn timestamp(&self) -> String;
    fn session_env(&self) -> Option<String>;
    fn pane_env(&self) -> Option<String>;
    fn current_session(&self) -> Option<String>;
    fn pane_state(&self) -> Vec<Value>;
    fn current_target(&self) -> Option<Target>;
    fn current_location(&self) -> Option<Location>;
}

pub fn run<P>(port: &P) -> Result<String, String>
where
    P: DiagnosePort,
{
    let panes = pane_projection(port.pane_state())?;
    let target = to_pretty_json(port.current_target())?;
    let location = to_pretty_json(port.current_location())?;

    Ok(format!(
        "timestamp={}\nZELLIJ_SESSION_NAME={}\nZELLIJ_PANE_ID={}\ncurrent_session={}\n\nall_pane_state=\n{}\n\nnav_current_target=\n{}\n\nnav_current_location=\n{}\n",
        port.timestamp(),
        port.session_env().unwrap_or_default(),
        port.pane_env().unwrap_or_default(),
        port.current_session().unwrap_or_default(),
        panes,
        target,
        location,
    ))
}

fn pane_projection(panes: Vec<Value>) -> Result<String, String> {
    let values = panes
        .into_iter()
        .map(|pane| {
            serde_json::json!({
                "id": pane.get("id").cloned().unwrap_or(Value::Null),
                "tab_id": pane.get("tab_id").cloned().unwrap_or(Value::Null),
                "title": pane.get("title").cloned().unwrap_or(Value::Null),
                "pane_command": pane.get("pane_command").cloned().unwrap_or(Value::Null),
                "pane_cwd": pane.get("pane_cwd").cloned().unwrap_or(Value::Null),
                "is_focused": pane.get("is_focused").cloned().unwrap_or(Value::Null),
                "is_selectable": pane.get("is_selectable").cloned().unwrap_or(Value::Null),
                "is_plugin": pane.get("is_plugin").cloned().unwrap_or(Value::Null),
                "is_floating": pane.get("is_floating").cloned().unwrap_or(Value::Null),
                "exited": pane.get("exited").cloned().unwrap_or(Value::Null),
            })
        })
        .collect::<Vec<_>>();
    serde_json::to_string_pretty(&values).map_err(|err| err.to_string())
}

fn to_pretty_json<T>(value: Option<T>) -> Result<String, String>
where
    T: serde::Serialize,
{
    let value = value
        .map(|inner| serde_json::to_value(inner).map_err(|err| err.to_string()))
        .transpose()?
        .unwrap_or(Value::Null);
    serde_json::to_string_pretty(&value).map_err(|err| err.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{Location, TargetKind};

    struct FakePort;

    impl DiagnosePort for FakePort {
        fn timestamp(&self) -> String {
            "123".to_string()
        }

        fn session_env(&self) -> Option<String> {
            Some("env-session".to_string())
        }

        fn pane_env(&self) -> Option<String> {
            Some("7".to_string())
        }

        fn current_session(&self) -> Option<String> {
            Some("current".to_string())
        }

        fn pane_state(&self) -> Vec<Value> {
            vec![serde_json::json!({
                "id": 7,
                "tab_id": 0,
                "title": "shell",
                "pane_command": "bash",
                "terminal_command": "bash",
                "pane_cwd": "/work",
                "is_focused": true,
                "is_selectable": true,
                "is_plugin": false,
                "is_floating": false,
                "exited": false,
            })]
        }

        fn current_target(&self) -> Option<Target> {
            Some(Target {
                kind: TargetKind::Pane,
                session: "current".to_string(),
                tab_id: Some(0),
                pane_id: Some(7),
                label: "Main / shell".to_string(),
            })
        }

        fn current_location(&self) -> Option<Location> {
            Some(Location {
                session: "current".to_string(),
                tab_id: Some(0),
                pane_id: Some(7),
                label: "Main / shell".to_string(),
            })
        }
    }

    #[test]
    fn renders_existing_diagnose_sections() {
        let output = run(&FakePort).unwrap();

        assert!(output.contains("timestamp=123"));
        assert!(output.contains("ZELLIJ_SESSION_NAME=env-session"));
        assert!(output.contains("all_pane_state="));
        assert!(output.contains("nav_current_target="));
        assert!(output.contains("nav_current_location="));
        assert!(output.contains("\"pane_command\": \"bash\""));
        assert!(!output.contains("terminal_command"));
    }
}
