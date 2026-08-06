use crate::domain::Target;
use crate::feature::toggle::LockGuard;
use serde_json::Value;

pub const MOVED: u8 = 0;
pub const FAILED: u8 = 1;
pub const NOOP: u8 = 3;
pub const COMMIT_FAILED: u8 = 4;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ApplyResult {
    Moved,
    Noop,
    Failed,
}

pub trait NavigatePort {
    fn acquire_navigation_lock(&self) -> Result<Box<dyn LockGuard + '_>, String>;
    fn capture_origin(&self) -> Result<Option<Target>, String>;
    fn selected_is_current(&self, target: &Target) -> Result<bool, String>;
    fn apply_navigation(&self, target: &Target) -> Result<ApplyResult, String>;
    fn commit_origin(&self, target: &Target) -> Result<(), String>;
    fn observe_navigation(&self, message: &str);
}

pub fn run<P>(port: &P, target_json: &str) -> Result<u8, String>
where
    P: NavigatePort,
{
    let _lock = match port.acquire_navigation_lock() {
        Ok(lock) => lock,
        Err(_) => return Ok(FAILED),
    };

    let Some(current) = port.capture_origin()? else {
        port.observe_navigation("navigation transaction aborted reason=current-target-unavailable");
        return Ok(FAILED);
    };

    let target = match parse_target(target_json) {
        Ok(target) => target,
        Err(reason) => {
            port.observe_navigation(&format!(
                "navigation transaction aborted reason=invalid-target target_reason={reason}"
            ));
            return Ok(FAILED);
        }
    };

    if port.selected_is_current(&target)? {
        port.observe_navigation(&format!(
            "navigation transaction aborted reason=target-equals-current target={}",
            target.summary()
        ));
        return Ok(NOOP);
    }

    match port.apply_navigation(&target)? {
        ApplyResult::Moved => commit_previous(port, &current, &target),
        ApplyResult::Noop => {
            port.observe_navigation(&format!(
                "navigation transaction aborted reason=no-op target={}",
                target.summary()
            ));
            Ok(NOOP)
        }
        ApplyResult::Failed => {
            port.observe_navigation(&format!(
                "navigation transaction aborted reason=focus-failed target={}",
                target.summary()
            ));
            Ok(FAILED)
        }
    }
}

fn commit_previous<P>(port: &P, current: &Target, target: &Target) -> Result<u8, String>
where
    P: NavigatePort,
{
    if port.commit_origin(current).is_ok() {
        port.observe_navigation(&format!(
            "navigation transaction committed previous={} target={}",
            current.summary(),
            target.summary()
        ));
        return Ok(MOVED);
    }

    port.observe_navigation(&format!(
        "navigation transaction partial reason=commit-failed movement=completed target={} return_target_not_committed={} previous_history_preserved=true",
        target.summary(),
        current.summary()
    ));
    Ok(COMMIT_FAILED)
}

fn parse_target(target_json: &str) -> Result<Target, String> {
    let value = serde_json::from_str::<Value>(target_json)
        .map_err(|err| format!("invalid-json error={err}"))?;

    if value
        .get("kind")
        .and_then(Value::as_str)
        .is_some_and(|kind| !matches!(kind, "session" | "tab" | "pane"))
    {
        return Err("unsupported-kind".to_string());
    }

    match serde_json::from_value::<Target>(value) {
        Ok(target) if target.valid() => Ok(target),
        Ok(target) => Err(target.validation_reason().to_string()),
        Err(err) => Err(format!("invalid-json error={err}")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{Target, TargetKind};
    use std::cell::RefCell;

    struct FakePort {
        current: Option<Target>,
        is_current: bool,
        apply: ApplyResult,
        lock_ok: bool,
        commit_ok: bool,
        saved: RefCell<Vec<Target>>,
        logs: RefCell<Vec<String>>,
    }

    impl NavigatePort for FakePort {
        fn acquire_navigation_lock(&self) -> Result<Box<dyn LockGuard + '_>, String> {
            if !self.lock_ok {
                return Err("locked".to_string());
            }
            Ok(Box::new(FakeLock))
        }

        fn capture_origin(&self) -> Result<Option<Target>, String> {
            Ok(self.current.clone())
        }

        fn selected_is_current(&self, _target: &Target) -> Result<bool, String> {
            Ok(self.is_current)
        }

        fn apply_navigation(&self, _target: &Target) -> Result<ApplyResult, String> {
            Ok(self.apply.clone())
        }

        fn commit_origin(&self, target: &Target) -> Result<(), String> {
            if !self.commit_ok {
                return Err("commit failed".to_string());
            }
            self.saved.borrow_mut().push(target.clone());
            Ok(())
        }

        fn observe_navigation(&self, message: &str) {
            self.logs.borrow_mut().push(message.to_string());
        }
    }

    struct FakeLock;
    impl LockGuard for FakeLock {}

    fn target(session: &str) -> Target {
        Target {
            kind: TargetKind::Session,
            session: session.to_string(),
            tab_id: None,
            pane_id: None,
            label: session.to_string(),
        }
    }

    #[test]
    fn moved_navigation_commits_origin_after_apply() {
        let port = FakePort {
            current: Some(target("current")),
            is_current: false,
            apply: ApplyResult::Moved,
            lock_ok: true,
            commit_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        let json = serde_json::to_string(&target("target")).unwrap();
        assert_eq!(run(&port, &json).unwrap(), MOVED);
        assert_eq!(port.saved.borrow().as_slice(), &[target("current")]);
    }

    #[test]
    fn failed_navigation_preserves_history() {
        let port = FakePort {
            current: Some(target("current")),
            is_current: false,
            apply: ApplyResult::Failed,
            lock_ok: true,
            commit_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        let json = serde_json::to_string(&target("target")).unwrap();
        assert_eq!(run(&port, &json).unwrap(), FAILED);
        assert!(port.saved.borrow().is_empty());
    }

    #[test]
    fn already_current_does_not_commit_origin() {
        let port = FakePort {
            current: Some(target("current")),
            is_current: true,
            apply: ApplyResult::Moved,
            lock_ok: true,
            commit_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        let json = serde_json::to_string(&target("target")).unwrap();
        assert_eq!(run(&port, &json).unwrap(), NOOP);
        assert!(port.saved.borrow().is_empty());
    }

    #[test]
    fn commit_failure_reports_partial_without_overwriting_history() {
        let port = FakePort {
            current: Some(target("current")),
            is_current: false,
            apply: ApplyResult::Moved,
            lock_ok: true,
            commit_ok: false,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        let json = serde_json::to_string(&target("target")).unwrap();
        assert_eq!(run(&port, &json).unwrap(), COMMIT_FAILED);
        assert!(port.saved.borrow().is_empty());
    }

    #[test]
    fn invalid_target_is_checked_after_origin_capture() {
        let port = FakePort {
            current: None,
            is_current: false,
            apply: ApplyResult::Moved,
            lock_ok: true,
            commit_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port, "{}").unwrap(), FAILED);
        assert_eq!(
            port.logs.borrow().as_slice(),
            &["navigation transaction aborted reason=current-target-unavailable"]
        );
    }

    #[test]
    fn unsupported_kind_has_bash_compatible_reason() {
        let port = FakePort {
            current: Some(target("current")),
            is_current: false,
            apply: ApplyResult::Moved,
            lock_ok: true,
            commit_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(
            run(&port, r#"{"kind":"workspace","session":"x"}"#).unwrap(),
            FAILED
        );
        assert_eq!(
            port.logs.borrow().as_slice(),
            &[
                "navigation transaction aborted reason=invalid-target target_reason=unsupported-kind"
            ]
        );
    }
}
