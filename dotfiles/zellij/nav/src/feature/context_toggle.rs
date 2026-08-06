pub trait ContextTogglePort {
    fn env_var(&self, name: &str) -> Option<String>;
    fn current_session(&self) -> Option<String>;
    fn current_pane_is_floating(&self) -> bool;
    fn focus_underlying(&self) -> u8;
    fn toggle(&self) -> u8;
    fn close_helper(&self, session: &str, pane_id: &str) -> u8;
    fn log(&self, message: &str);
}

pub fn run(port: &impl ContextTogglePort) -> Result<u8, String> {
    let mut is_helper = port.env_var("ZELLIJ_NAV_HELPER").as_deref() == Some("1");
    let focus_underlying = port.env_var("ZELLIJ_NAV_FOCUS_UNDERLYING").as_deref() == Some("1");

    if !is_helper && focus_underlying {
        is_helper = true;
        port.log("toggle helper inferred reason=legacy-focus-underlying-marker");
    }
    if !is_helper && port.current_pane_is_floating() {
        is_helper = true;
        port.log("toggle helper inferred reason=legacy-floating-pane");
    }

    let helper_session = is_helper.then(|| port.current_session()).flatten();
    if focus_underlying && port.focus_underlying() != 0 {
        port.log("toggle continuing with degraded current-context capture");
    }

    let status = port.toggle();
    if let Some(session) = helper_session {
        let pane_id = port.env_var("ZELLIJ_PANE_ID").unwrap_or_default();
        let _ = port.close_helper(&session, &pane_id);
    }

    Ok(status)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    struct FakePort {
        logs: RefCell<Vec<String>>,
        focus: u8,
    }

    impl ContextTogglePort for FakePort {
        fn env_var(&self, name: &str) -> Option<String> {
            match name {
                "ZELLIJ_NAV_FOCUS_UNDERLYING" => Some("1".to_string()),
                "ZELLIJ_PANE_ID" => Some("42".to_string()),
                _ => None,
            }
        }

        fn current_session(&self) -> Option<String> {
            Some("current".to_string())
        }

        fn current_pane_is_floating(&self) -> bool {
            false
        }

        fn focus_underlying(&self) -> u8 {
            self.focus
        }

        fn toggle(&self) -> u8 {
            0
        }

        fn close_helper(&self, session: &str, pane_id: &str) -> u8 {
            self.logs
                .borrow_mut()
                .push(format!("close:{session}:{pane_id}"));
            0
        }

        fn log(&self, message: &str) {
            self.logs.borrow_mut().push(message.to_string());
        }
    }

    #[test]
    fn focus_underlying_marker_sets_helper_and_closes_after_toggle() {
        let port = FakePort {
            logs: RefCell::new(Vec::new()),
            focus: 0,
        };

        run(&port).unwrap();

        assert!(port
            .logs
            .borrow()
            .contains(&"toggle helper inferred reason=legacy-focus-underlying-marker".to_string()));
        assert!(port.logs.borrow().contains(&"close:current:42".to_string()));
    }
}
