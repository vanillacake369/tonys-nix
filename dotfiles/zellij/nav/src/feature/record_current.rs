use crate::domain::Target;
use crate::feature::toggle::LockGuard;

pub const DONE: u8 = 0;

pub trait RecordPort {
    fn acquire_record_lock(&self) -> Result<Box<dyn LockGuard + '_>, String>;
    fn capture_record_target(&self) -> Result<Option<Target>, String>;
    fn save_record_target(&self, target: &Target) -> Result<(), String>;
    fn observe_record(&self, message: &str);
}

pub fn run<P>(port: &P, reason: &str) -> Result<u8, String>
where
    P: RecordPort,
{
    let _lock = match port.acquire_record_lock() {
        Ok(lock) => lock,
        Err(_) => return Ok(DONE),
    };

    let Some(current) = port.capture_record_target()? else {
        port.observe_record(&format!(
            "could not capture current target before external navigation reason={reason}"
        ));
        return Ok(DONE);
    };

    if port.save_record_target(&current).is_ok() {
        port.observe_record(&format!(
            "session-manager best-effort state capture reason={reason} target={}",
            current.summary()
        ));
        return Ok(DONE);
    }

    port.observe_record(&format!(
        "session-manager best-effort state capture failed reason={reason} target={} previous_history_preserved=true",
        current.summary()
    ));
    Ok(DONE)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{Target, TargetKind};
    use std::cell::RefCell;

    struct FakePort {
        current: Option<Target>,
        lock_ok: bool,
        save_ok: bool,
        saved: RefCell<Vec<Target>>,
        logs: RefCell<Vec<String>>,
    }

    impl RecordPort for FakePort {
        fn acquire_record_lock(&self) -> Result<Box<dyn LockGuard + '_>, String> {
            if !self.lock_ok {
                return Err("locked".to_string());
            }
            Ok(Box::new(FakeLock))
        }

        fn capture_record_target(&self) -> Result<Option<Target>, String> {
            Ok(self.current.clone())
        }

        fn save_record_target(&self, target: &Target) -> Result<(), String> {
            if !self.save_ok {
                return Err("save failed".to_string());
            }
            self.saved.borrow_mut().push(target.clone());
            Ok(())
        }

        fn observe_record(&self, message: &str) {
            self.logs.borrow_mut().push(message.to_string());
        }
    }

    struct FakeLock;
    impl LockGuard for FakeLock {}

    fn target(session: &str) -> Target {
        Target {
            kind: TargetKind::Pane,
            session: session.to_string(),
            tab_id: Some(0),
            pane_id: Some(7),
            label: session.to_string(),
        }
    }

    #[test]
    fn records_current_target_for_external_navigation() {
        let port = FakePort {
            current: Some(target("current")),
            lock_ok: true,
            save_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port, "session-manager").unwrap(), DONE);
        assert_eq!(port.saved.borrow().as_slice(), &[target("current")]);
        assert!(port.logs.borrow()[0].contains("best-effort state capture"));
    }

    #[test]
    fn missing_current_is_best_effort_noop() {
        let port = FakePort {
            current: None,
            lock_ok: true,
            save_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port, "session-manager").unwrap(), DONE);
        assert!(port.saved.borrow().is_empty());
        assert!(port.logs.borrow()[0].contains("could not capture current target"));
    }

    #[test]
    fn save_failure_preserves_previous_history() {
        let port = FakePort {
            current: Some(target("current")),
            lock_ok: true,
            save_ok: false,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port, "session-manager").unwrap(), DONE);
        assert!(port.saved.borrow().is_empty());
        assert!(port.logs.borrow()[0].contains("previous_history_preserved=true"));
    }

    #[test]
    fn lock_failure_is_best_effort_noop() {
        let port = FakePort {
            current: Some(target("current")),
            lock_ok: false,
            save_ok: true,
            saved: RefCell::new(Vec::new()),
            logs: RefCell::new(Vec::new()),
        };

        assert_eq!(run(&port, "session-manager").unwrap(), DONE);
        assert!(port.saved.borrow().is_empty());
        assert!(port.logs.borrow().is_empty());
    }
}
