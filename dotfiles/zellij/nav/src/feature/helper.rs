use serde_json::Value;

pub trait HelperPort {
    fn current_session(&self) -> Option<String>;
    fn panes(&self, session: &str) -> Vec<Value>;
    fn focus_previous_pane(&self) -> bool;
    fn close_pane(&self, session: &str, pane_id: &str) -> bool;
    fn sleep_millis(&self, millis: u64);
    fn log(&self, message: &str);
}

pub fn focus_underlying(port: &impl HelperPort) -> Result<u8, String> {
    let Some(self_pane) = std::env::var("ZELLIJ_PANE_ID")
        .ok()
        .filter(|id| !id.is_empty())
    else {
        return Ok(0);
    };
    let Some(session) = port.current_session() else {
        return Err("missing current session".to_string());
    };
    let panes = port.panes(&session);

    if has_focused_terminal(&panes, &self_pane, false) {
        return Ok(0);
    }
    if !has_focused_self(&panes, &self_pane) {
        port.log(&format!(
            "underlying capture unavailable reason=helper-not-focused self_pane={self_pane}"
        ));
        return Ok(1);
    }
    if !port.focus_previous_pane() {
        port.log(&format!(
            "underlying capture failed action=focus-previous-pane self_pane={self_pane}"
        ));
        return Ok(1);
    }

    for _ in 0..5 {
        if has_focused_terminal(&port.panes(&session), &self_pane, false) {
            port.log(&format!(
                "underlying pane focused for capture self_pane={self_pane}"
            ));
            return Ok(0);
        }
        port.sleep_millis(50);
    }

    port.log(&format!(
        "underlying capture failed reason=no-focused-terminal self_pane={self_pane}"
    ));
    Ok(1)
}

pub fn close(port: &impl HelperPort, session: &str, pane_id: &str) -> Result<u8, String> {
    if session.is_empty() {
        port.log(&format!(
            "helper pane close skipped reason=missing-session pane={}",
            empty_as_unknown(pane_id)
        ));
        return Ok(0);
    }

    let Some(pane_number) = terminal_pane_number(pane_id) else {
        port.log(&format!(
            "helper pane close skipped reason=missing-pane-id session={session}"
        ));
        return Ok(0);
    };

    if !is_verified_helper(&port.panes(session), &pane_number) {
        port.log(&format!(
            "helper pane close skipped reason=not-helper-pane session={session} pane={pane_number}"
        ));
        return Ok(0);
    }

    let pane = format!("terminal_{pane_number}");
    port.log(&format!(
        "closing helper pane session={session} pane={pane}"
    ));
    if port.close_pane(session, &pane) {
        port.log(&format!("closed helper pane session={session} pane={pane}"));
        return Ok(0);
    }

    port.log(&format!(
        "helper pane close failed session={session} pane={pane}"
    ));
    Ok(1)
}

fn has_focused_terminal(panes: &[Value], self_pane: &str, allow_self: bool) -> bool {
    panes.iter().any(|pane| {
        pane.get("is_focused").and_then(Value::as_bool) == Some(true)
            && (allow_self
                || pane
                    .get("id")
                    .and_then(Value::as_u64)
                    .map(|id| id.to_string())
                    != Some(self_pane.to_string()))
            && selectable_terminal(pane)
    })
}

fn has_focused_self(panes: &[Value], self_pane: &str) -> bool {
    panes.iter().any(|pane| {
        pane.get("is_focused").and_then(Value::as_bool) == Some(true)
            && pane
                .get("id")
                .and_then(Value::as_u64)
                .map(|id| id.to_string())
                == Some(self_pane.to_string())
    })
}

fn selectable_terminal(pane: &Value) -> bool {
    pane.get("is_plugin").and_then(Value::as_bool) == Some(false)
        && pane.get("is_selectable").and_then(Value::as_bool) == Some(true)
        && pane.get("exited").and_then(Value::as_bool) == Some(false)
}

fn is_verified_helper(panes: &[Value], pane_number: &str) -> bool {
    panes.iter().any(|pane| {
        pane.get("id")
            .and_then(Value::as_u64)
            .map(|id| id.to_string())
            == Some(pane_number.to_string())
            && pane.get("is_floating").and_then(Value::as_bool) == Some(true)
            && pane.get("is_plugin").and_then(Value::as_bool) == Some(false)
            && {
                let text = helper_text(pane);
                text.contains("zellij-pane-picker")
                    || text.contains("zellij-context-toggle")
                    || text.contains("zellij-picker")
                    || text.contains("zellij-context")
            }
    })
}

fn helper_text(pane: &Value) -> String {
    ["pane_command", "terminal_command", "title"]
        .iter()
        .filter_map(|key| pane.get(*key).and_then(Value::as_str))
        .collect::<Vec<_>>()
        .join(" ")
}

fn terminal_pane_number(pane_id: &str) -> Option<String> {
    let pane_id = pane_id.strip_prefix("terminal_").unwrap_or(pane_id);
    (!pane_id.is_empty() && pane_id.chars().all(|ch| ch.is_ascii_digit()))
        .then(|| pane_id.to_string())
}

fn empty_as_unknown(value: &str) -> &str {
    if value.is_empty() {
        return "unknown";
    }
    value
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    struct FakePort {
        logs: RefCell<Vec<String>>,
    }

    impl HelperPort for FakePort {
        fn current_session(&self) -> Option<String> {
            Some("current".to_string())
        }

        fn panes(&self, _session: &str) -> Vec<Value> {
            serde_json::json!([
                {
                    "id": 42,
                    "is_focused": true,
                    "is_floating": true,
                    "is_plugin": false,
                    "is_selectable": true,
                    "exited": false,
                    "pane_command": "zellij-context-toggle"
                }
            ])
            .as_array()
            .unwrap()
            .clone()
        }

        fn focus_previous_pane(&self) -> bool {
            true
        }

        fn close_pane(&self, _session: &str, _pane_id: &str) -> bool {
            true
        }

        fn sleep_millis(&self, _millis: u64) {}

        fn log(&self, message: &str) {
            self.logs.borrow_mut().push(message.to_string());
        }
    }

    #[test]
    fn closes_only_verified_helper_pane() {
        let port = FakePort {
            logs: RefCell::new(Vec::new()),
        };

        close(&port, "current", "42").unwrap();

        assert!(port
            .logs
            .borrow()
            .contains(&"closed helper pane session=current pane=terminal_42".to_string()));
    }
}
