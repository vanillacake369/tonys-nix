use crate::domain::Target;

pub const MOVED: u8 = 0;
pub const FAILED: u8 = 1;
pub const COMMIT_FAILED: u8 = 4;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Route {
    Block,
    Cli,
    Plugin,
    Sidecar,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ApplyResult {
    Moved,
    SessionMissing,
    Noop,
    Failed,
}

pub trait TogglePort {
    fn acquire_lock(&self) -> Result<Box<dyn LockGuard + '_>, String>;
    fn previous(&self) -> Result<Option<Target>, String>;
    fn current(&self) -> Result<Option<Target>, String>;
    fn target_is_current(&self, target: &Target) -> Result<bool, String>;
    fn route(&self, target: &Target) -> Route;
    fn apply(&self, target: &Target, route: &Route) -> Result<ApplyResult, String>;
    fn save_previous(&self, target: &Target) -> Result<(), String>;
    fn clear_previous(&self, reason: &str) -> Result<(), String>;
    fn log(&self, message: &str);
}

pub trait LockGuard {}

pub fn run<P>(port: &P) -> Result<u8, String>
where
    P: TogglePort,
{
    let _lock = match port.acquire_lock() {
        Ok(lock) => lock,
        Err(_) => return Ok(MOVED),
    };

    let Some(target) = port.previous()? else {
        port.log("toggle no-op reason=no-previous-target");
        return Ok(MOVED);
    };

    let Some(current) = port.current()? else {
        port.log("toggle no-op reason=current-target-unavailable");
        return Ok(MOVED);
    };

    if port.target_is_current(&target)? {
        port.clear_previous("target-equals-current")?;
        port.log("toggle no-op reason=target-equals-current");
        return Ok(MOVED);
    }

    let route = port.route(&target);
    let status = port.apply(&target, &route)?;

    if status == ApplyResult::Moved {
        return commit_swap(port, &current);
    }

    if status == ApplyResult::SessionMissing {
        port.clear_previous("session-missing")?;
        port.log(&format!(
            "toggle no-op reason=session-missing target={}",
            target.summary()
        ));
        return Ok(MOVED);
    }

    let reason = if status == ApplyResult::Noop {
        "no-movement"
    } else {
        "focus-failed"
    };
    port.log(&format!(
        "toggle no-op reason={reason} target={}",
        target.summary()
    ));
    Ok(FAILED)
}

fn commit_swap<P>(port: &P, current: &Target) -> Result<u8, String>
where
    P: TogglePort,
{
    if port.save_previous(current).is_ok() {
        port.log("toggle swapped previous-target");
        return Ok(MOVED);
    }

    port.log(&format!(
        "toggle partial reason=commit-failed movement=completed return_target_not_committed={} previous_history_preserved=true",
        current.summary()
    ));
    Ok(COMMIT_FAILED)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{Target, TargetKind};
    use std::cell::RefCell;

    struct FakePort {
        previous: Option<Target>,
        current: Option<Target>,
        is_current: bool,
        apply: ApplyResult,
        saved: RefCell<Vec<Target>>,
        cleared: RefCell<Vec<String>>,
        logs: RefCell<Vec<String>>,
    }

    impl TogglePort for FakePort {
        fn acquire_lock(&self) -> Result<Box<dyn LockGuard + '_>, String> {
            Ok(Box::new(FakeLock))
        }

        fn previous(&self) -> Result<Option<Target>, String> {
            Ok(self.previous.clone())
        }

        fn current(&self) -> Result<Option<Target>, String> {
            Ok(self.current.clone())
        }

        fn target_is_current(&self, _target: &Target) -> Result<bool, String> {
            Ok(self.is_current)
        }

        fn route(&self, _target: &Target) -> Route {
            Route::Cli
        }

        fn apply(&self, _target: &Target, _route: &Route) -> Result<ApplyResult, String> {
            Ok(self.apply.clone())
        }

        fn save_previous(&self, target: &Target) -> Result<(), String> {
            self.saved.borrow_mut().push(target.clone());
            Ok(())
        }

        fn clear_previous(&self, reason: &str) -> Result<(), String> {
            self.cleared.borrow_mut().push(reason.to_string());
            Ok(())
        }

        fn log(&self, message: &str) {
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
    fn moved_swap_commits_current_after_apply() {
        let port = FakePort {
            previous: Some(target("target")),
            current: Some(target("current")),
            is_current: false,
            apply: ApplyResult::Moved,
            saved: RefCell::new(Vec::new()),
            cleared: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port).unwrap(), MOVED);
        assert_eq!(port.saved.borrow().as_slice(), &[target("current")]);
        assert!(port.cleared.borrow().is_empty());
    }

    #[test]
    fn failed_apply_preserves_previous_history() {
        let port = FakePort {
            previous: Some(target("target")),
            current: Some(target("current")),
            is_current: false,
            apply: ApplyResult::Failed,
            saved: RefCell::new(Vec::new()),
            cleared: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port).unwrap(), FAILED);
        assert!(port.saved.borrow().is_empty());
        assert!(port.cleared.borrow().is_empty());
    }

    #[test]
    fn session_missing_clears_previous() {
        let port = FakePort {
            previous: Some(target("target")),
            current: Some(target("current")),
            is_current: false,
            apply: ApplyResult::SessionMissing,
            saved: RefCell::new(Vec::new()),
            cleared: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port).unwrap(), MOVED);
        assert_eq!(port.cleared.borrow().as_slice(), &["session-missing"]);
    }
}
