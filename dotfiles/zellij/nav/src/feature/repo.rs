use std::path::{Path, PathBuf};

pub trait RepoPort {
    fn repo_dirs(&self) -> Result<Vec<PathBuf>, String>;
    fn select_repo(&self, candidates: &str) -> Result<Option<String>, String>;
    fn attach_session(&self, dir: &PathBuf, session: &str) -> Result<u8, String>;
    fn log(&self, message: &str);
}

pub fn run(port: &impl RepoPort) -> Result<u8, String> {
    let dirs = sorted_repo_dirs(port)?;
    let candidates = dirs
        .iter()
        .map(|dir| dir.to_string_lossy().to_string())
        .collect::<Vec<_>>()
        .join("\n")
        + "\n";

    let Some(selection) = port.select_repo(&candidates)? else {
        port.log("repo picker cancelled");
        return Ok(0);
    };

    let selected = PathBuf::from(selection);
    let dir = dirs
        .into_iter()
        .find(|dir| dir == &selected)
        .ok_or_else(|| "selected repo is not in discovered repo list".to_string())?;
    attach(port, dir)
}

pub fn run_to(port: &impl RepoPort, repo: &str) -> Result<u8, String> {
    validate_repo_name(repo)?;
    let dir = sorted_repo_dirs(port)?
        .into_iter()
        .find(|dir| dir.file_name().and_then(|name| name.to_str()) == Some(repo))
        .ok_or_else(|| format!("repo not found: {repo}"))?;
    attach(port, dir)
}

fn sorted_repo_dirs(port: &impl RepoPort) -> Result<Vec<PathBuf>, String> {
    let mut dirs = port.repo_dirs()?;
    dirs.sort_by(|left, right| left.to_string_lossy().cmp(&right.to_string_lossy()));
    dirs.dedup();
    Ok(dirs)
}

fn attach(port: &impl RepoPort, dir: PathBuf) -> Result<u8, String> {
    let session = session_name(&dir)?;
    port.log(&format!(
        "repo attach session={} dir={}",
        session,
        dir.to_string_lossy()
    ));
    port.attach_session(&dir, &session)
}

fn validate_repo_name(repo: &str) -> Result<(), String> {
    if repo.is_empty()
        || repo == "."
        || repo == ".."
        || repo.contains('/')
        || repo.contains('\\')
        || repo.contains('\0')
    {
        return Err(format!("invalid repo name: {repo}"));
    }
    Ok(())
}

fn session_name(dir: &Path) -> Result<String, String> {
    let name = dir
        .file_name()
        .and_then(|name| name.to_str())
        .ok_or_else(|| format!("missing repo basename: {}", dir.to_string_lossy()))?;
    let session = name
        .chars()
        .map(|ch| {
            if ch.is_ascii_alphanumeric() || matches!(ch, '.' | '_' | '-') {
                ch
            } else {
                '-'
            }
        })
        .collect::<String>()
        .trim_matches('-')
        .to_string();

    if session.is_empty() {
        return Err(format!(
            "repo basename cannot form session name: {}",
            dir.to_string_lossy()
        ));
    }
    Ok(session)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    struct FakePort {
        dirs: Vec<PathBuf>,
        selection: Option<String>,
        attached: RefCell<Vec<(PathBuf, String)>>,
        logs: RefCell<Vec<String>>,
    }

    impl FakePort {
        fn new(dirs: Vec<&str>) -> Self {
            Self {
                dirs: dirs.into_iter().map(PathBuf::from).collect(),
                selection: None,
                attached: RefCell::new(Vec::new()),
                logs: RefCell::new(Vec::new()),
            }
        }

        fn with_selection(mut self, selection: &str) -> Self {
            self.selection = Some(selection.to_string());
            self
        }
    }

    impl RepoPort for FakePort {
        fn repo_dirs(&self) -> Result<Vec<PathBuf>, String> {
            Ok(self.dirs.clone())
        }

        fn select_repo(&self, candidates: &str) -> Result<Option<String>, String> {
            assert!(!candidates.is_empty());
            Ok(self.selection.clone())
        }

        fn attach_session(&self, dir: &PathBuf, session: &str) -> Result<u8, String> {
            self.attached
                .borrow_mut()
                .push((dir.clone(), session.to_string()));
            Ok(0)
        }

        fn log(&self, message: &str) {
            self.logs.borrow_mut().push(message.to_string());
        }
    }

    #[test]
    fn repo_to_attaches_named_repo_under_discovered_dirs() {
        let port = FakePort::new(vec!["/home/me/dev/tonys-blog", "/home/me/dev/tonys-nix"]);

        assert_eq!(run_to(&port, "tonys-blog").unwrap(), 0);
        assert_eq!(
            port.attached.borrow().as_slice(),
            &[(
                PathBuf::from("/home/me/dev/tonys-blog"),
                "tonys-blog".to_string()
            )]
        );
    }

    #[test]
    fn repo_to_rejects_path_like_names() {
        let port = FakePort::new(vec!["/home/me/dev/tonys-blog"]);

        let err = run_to(&port, "../tonys-blog").unwrap_err();

        assert!(err.contains("invalid repo name"));
        assert!(port.attached.borrow().is_empty());
    }

    #[test]
    fn repo_picker_cancel_exits_successfully_without_attach() {
        let port = FakePort::new(vec!["/home/me/dev/tonys-blog"]);

        assert_eq!(run(&port).unwrap(), 0);
        assert!(port.attached.borrow().is_empty());
        assert!(port
            .logs
            .borrow()
            .contains(&"repo picker cancelled".to_string()));
    }

    #[test]
    fn repo_picker_attaches_selected_directory_with_sanitized_session() {
        let port = FakePort::new(vec!["/home/me/dev/tonys blog"])
            .with_selection("/home/me/dev/tonys blog");

        assert_eq!(run(&port).unwrap(), 0);
        assert_eq!(
            port.attached.borrow().as_slice(),
            &[(
                PathBuf::from("/home/me/dev/tonys blog"),
                "tonys-blog".to_string()
            )]
        );
    }
}
