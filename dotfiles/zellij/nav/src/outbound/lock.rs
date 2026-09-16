use super::process::process_exists;
use super::{now_seconds, Runtime};
use crate::feature::toggle::LockGuard;
use std::fs;

pub(super) struct LeaseLock<'a> {
    rt: &'a Runtime,
}

impl<'a> LeaseLock<'a> {
    pub(super) fn acquire(rt: &'a Runtime) -> Result<Self, String> {
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
