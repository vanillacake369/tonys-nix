use crate::feature::sidecar::LaunchFailure;
use std::fs;
#[cfg(unix)]
use std::os::unix::fs::FileTypeExt;
use std::path::{Path, PathBuf};
use std::process::Command;

pub(super) fn run_output(command: &mut Command) -> String {
    command
        .output()
        .ok()
        .filter(|output| output.status.success())
        .map(|output| String::from_utf8_lossy(&output.stdout).to_string())
        .unwrap_or_default()
}

pub(super) fn run_status(command: &mut Command) -> bool {
    command
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

pub(super) fn run_capture(command: &mut Command) -> Result<String, String> {
    let output = command.output().map_err(|err| err.to_string())?;
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    let combined = format!("{stdout}{stderr}");

    if output.status.success() {
        return Ok(combined);
    }
    Err(combined)
}

pub(super) fn run_launch(command: &mut Command) -> Result<String, LaunchFailure> {
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

pub(super) fn with_wezterm_socket(command: &mut Command) {
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

pub(super) fn command_available(command: &str) -> bool {
    Command::new("sh")
        .arg("-c")
        .arg("command -v \"$ZELLIJ_NAV_COMMAND_CHECK\" >/dev/null 2>&1")
        .env("ZELLIJ_NAV_COMMAND_CHECK", command)
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

pub(super) fn process_exists(pid: u32) -> bool {
    Command::new("kill")
        .arg("-0")
        .arg(pid.to_string())
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}
