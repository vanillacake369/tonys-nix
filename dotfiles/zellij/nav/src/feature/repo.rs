use serde::Serialize;
use std::collections::{BTreeMap, BTreeSet, HashMap};
use std::path::{Path, PathBuf};

// macOS' default Zellij socket directory leaves only about 24 bytes for the
// session name before reaching the Unix socket path limit. Reserve nine bytes
// for `-` plus the stable path hash and keep the readable prefix bounded.
const SESSION_BASE_MAX_CHARS: usize = 15;

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
pub struct Project {
    pub path: PathBuf,
    pub display_name: String,
    pub session_name: String,
    pub connect_session_name: String,
    pub layout: Option<String>,
    #[serde(skip)]
    pub naming_conflict: Option<String>,
}

struct ProjectEntry {
    path: PathBuf,
    display_name: String,
    base: String,
}

pub trait RepoPort {
    fn repo_dirs(&self) -> Result<Vec<PathBuf>, String>;
    fn canonicalize_repo(&self, path: &Path) -> Result<PathBuf, String>;
    fn project_layouts(&self) -> Result<BTreeMap<String, String>, String>;
    fn active_sessions(&self) -> Result<BTreeSet<String>, String>;
    fn select_repo(&self, candidates: &str) -> Result<Option<String>, String>;
    fn current_dir(&self) -> Result<PathBuf, String>;
    fn ensure_project_session(&self, project: &Project) -> Result<(), String>;
    fn launch_project_session(&self, project: &Project) -> Result<u8, String>;
    fn log(&self, message: &str);
}

pub fn run(port: &impl RepoPort) -> Result<u8, String> {
    let projects = projects(port)?;
    let candidates = projects
        .iter()
        .map(|project| project.path.to_string_lossy().to_string())
        .collect::<Vec<_>>()
        .join("\n")
        + "\n";
    let Some(selection) = port.select_repo(&candidates)? else {
        port.log("repo picker cancelled");
        return Ok(0);
    };
    let selected = PathBuf::from(selection);
    let project = projects
        .into_iter()
        .find(|project| project.path == selected)
        .ok_or_else(|| "selected repo is not in discovered repo list".to_string())?;
    open_project(port, project)
}

pub fn run_to(port: &impl RepoPort, repo: &str) -> Result<u8, String> {
    validate_repo_name(repo)?;
    let project = resolve_unique_project(projects(port)?, repo)?;
    open_project(port, project)
}

fn resolve_unique_project(projects: Vec<Project>, repo: &str) -> Result<Project, String> {
    let matches = projects
        .into_iter()
        .filter(|project| project.display_name == repo)
        .collect::<Vec<_>>();
    if matches.len() > 1 {
        let candidates = matches
            .iter()
            .map(|project| format!("{} ({})", project.session_name, project.path.display()))
            .collect::<Vec<_>>()
            .join(", ");
        return Err(format!(
            "ambiguous repo name: {repo}; candidates: {candidates}"
        ));
    }
    matches
        .into_iter()
        .next()
        .ok_or_else(|| format!("repo not found: {repo}"))
}

pub fn projects_json(port: &impl RepoPort) -> Result<String, String> {
    serde_json::to_string(&projects(port)?).map_err(|err| err.to_string())
}

pub fn auto_project(port: &impl RepoPort) -> Result<u8, String> {
    let cwd = port.canonicalize_repo(&port.current_dir()?)?;
    let project = projects(port)?
        .into_iter()
        .filter(|project| cwd.starts_with(&project.path))
        .max_by_key(|project| project.path.components().count());
    let Some(project) = project else {
        return Ok(2);
    };
    open_project(port, project)
}

pub fn reload_projects(port: &impl RepoPort) -> Result<u8, String> {
    let failures = projects(port)?
        .iter()
        .filter_map(|project| reload_project(port, project))
        .collect::<Vec<_>>();
    if failures.is_empty() {
        port.log("project reload completed");
        return Ok(0);
    }
    Err(format!("project reload failed: {}", failures.join("; ")))
}

fn reload_project(port: &impl RepoPort, project: &Project) -> Option<String> {
    let result = project
        .naming_conflict
        .clone()
        .map_or_else(|| port.ensure_project_session(project), Err);
    result.err().map(|err| {
        port.log(&format!(
            "project reload failed session={} dir={} error={err}",
            project.connect_session_name,
            project.path.display()
        ));
        format!("{}: {err}", project.connect_session_name)
    })
}

fn projects(port: &impl RepoPort) -> Result<Vec<Project>, String> {
    let layouts = port.project_layouts()?;
    let active_sessions = port.active_sessions()?;
    let entries = project_entries(port)?;
    let base_counts = count_bases(&entries);
    Ok(entries
        .into_iter()
        .map(|entry| build_project(entry, &base_counts, &active_sessions, &layouts))
        .collect())
}

fn project_entries(port: &impl RepoPort) -> Result<Vec<ProjectEntry>, String> {
    let paths = canonical_project_paths(port)?;
    paths
        .into_iter()
        .map(|path| {
            let display_name = basename(&path)?;
            let base = sanitize_session_name(&display_name, &path)?;
            Ok(ProjectEntry {
                path,
                display_name,
                base,
            })
        })
        .collect()
}

fn canonical_project_paths(port: &impl RepoPort) -> Result<Vec<PathBuf>, String> {
    let mut paths = port
        .repo_dirs()?
        .into_iter()
        .filter_map(|path| canonical_project_path(port, path))
        .collect::<Vec<_>>();
    paths.sort_by(|left, right| left.to_string_lossy().cmp(&right.to_string_lossy()));
    paths.dedup();
    Ok(paths)
}

fn canonical_project_path(port: &impl RepoPort, path: PathBuf) -> Option<PathBuf> {
    match port.canonicalize_repo(&path) {
        Ok(path) => Some(path),
        Err(err) => {
            port.log(&format!(
                "repo canonicalize skipped path={} error={err}",
                path.to_string_lossy()
            ));
            None
        }
    }
}

fn count_bases(entries: &[ProjectEntry]) -> HashMap<String, usize> {
    let mut counts = HashMap::new();
    for entry in entries {
        *counts.entry(entry.base.clone()).or_insert(0) += 1;
    }
    counts
}

fn build_project(
    entry: ProjectEntry,
    base_counts: &HashMap<String, usize>,
    active_sessions: &BTreeSet<String>,
    layouts: &BTreeMap<String, String>,
) -> Project {
    let is_unique = base_counts.get(&entry.base) == Some(&1);
    let (session_name, connect_session_name) = session_names(&entry, is_unique, active_sessions);
    let naming_conflict = naming_conflict(&entry.base, is_unique, active_sessions);
    let layout = project_layout(&entry, layouts);
    Project {
        path: entry.path,
        display_name: entry.display_name,
        session_name,
        connect_session_name,
        layout,
        naming_conflict,
    }
}

fn session_names(
    entry: &ProjectEntry,
    is_unique: bool,
    active_sessions: &BTreeSet<String>,
) -> (String, String) {
    let bounded = entry
        .base
        .chars()
        .take(SESSION_BASE_MAX_CHARS)
        .collect::<String>();
    let hashed = format!("{}-{:08x}", bounded, stable_path_hash(&entry.path));
    let session = if is_unique && entry.base.len() <= 24 {
        entry.base.clone()
    } else {
        hashed.clone()
    };
    let connect =
        if is_unique && !active_sessions.contains(&entry.base) && active_sessions.contains(&hashed)
        {
            hashed
        } else {
            session.clone()
        };
    (session, connect)
}

fn naming_conflict(
    base: &str,
    is_unique: bool,
    active_sessions: &BTreeSet<String>,
) -> Option<String> {
    (!is_unique && active_sessions.contains(base)).then(|| {
        format!("ambiguous active project session: {base}; close it before creating hashed collision sessions")
    })
}

fn project_layout(entry: &ProjectEntry, layouts: &BTreeMap<String, String>) -> Option<String> {
    layouts
        .get(entry.path.to_string_lossy().as_ref())
        .or_else(|| layouts.get(&entry.display_name))
        .cloned()
}

fn open_project(port: &impl RepoPort, project: Project) -> Result<u8, String> {
    if let Some(err) = &project.naming_conflict {
        return Err(err.clone());
    }
    port.log(&format!(
        "project open session={} dir={}",
        project.connect_session_name,
        project.path.to_string_lossy()
    ));
    port.launch_project_session(&project)
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

fn basename(dir: &Path) -> Result<String, String> {
    dir.file_name()
        .and_then(|name| name.to_str())
        .map(str::to_string)
        .ok_or_else(|| format!("missing repo basename: {}", dir.to_string_lossy()))
}

fn sanitize_session_name(name: &str, dir: &Path) -> Result<String, String> {
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

fn stable_path_hash(path: &Path) -> u32 {
    path.to_string_lossy()
        .as_bytes()
        .iter()
        .fold(0x811c9dc5u32, |hash, byte| {
            (hash ^ u32::from(*byte)).wrapping_mul(0x01000193)
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    struct FakePort {
        dirs: Vec<PathBuf>,
        layouts: BTreeMap<String, String>,
        active_sessions: BTreeSet<String>,
        selection: Option<String>,
        attached: RefCell<Vec<(PathBuf, String)>>,
        ensured: RefCell<Vec<String>>,
        ensure_failures: BTreeSet<String>,
        logs: RefCell<Vec<String>>,
    }

    impl FakePort {
        fn new(dirs: Vec<&str>) -> Self {
            Self {
                dirs: dirs.into_iter().map(PathBuf::from).collect(),
                layouts: BTreeMap::new(),
                active_sessions: BTreeSet::new(),
                selection: None,
                attached: RefCell::new(Vec::new()),
                ensured: RefCell::new(Vec::new()),
                ensure_failures: BTreeSet::new(),
                logs: RefCell::new(Vec::new()),
            }
        }
        fn with_selection(mut self, selection: &str) -> Self {
            self.selection = Some(selection.to_string());
            self
        }
        fn with_ensure_failure(mut self, session: &str) -> Self {
            self.ensure_failures.insert(session.to_string());
            self
        }
    }

    impl RepoPort for FakePort {
        fn repo_dirs(&self) -> Result<Vec<PathBuf>, String> {
            Ok(self.dirs.clone())
        }
        fn canonicalize_repo(&self, path: &Path) -> Result<PathBuf, String> {
            Ok(path.to_path_buf())
        }
        fn project_layouts(&self) -> Result<BTreeMap<String, String>, String> {
            Ok(self.layouts.clone())
        }
        fn active_sessions(&self) -> Result<BTreeSet<String>, String> {
            Ok(self.active_sessions.clone())
        }
        fn select_repo(&self, candidates: &str) -> Result<Option<String>, String> {
            assert!(!candidates.is_empty());
            Ok(self.selection.clone())
        }
        fn current_dir(&self) -> Result<PathBuf, String> {
            Ok(PathBuf::from("/outside"))
        }
        fn launch_project_session(&self, project: &Project) -> Result<u8, String> {
            self.attached
                .borrow_mut()
                .push((project.path.clone(), project.connect_session_name.clone()));
            Ok(0)
        }
        fn ensure_project_session(&self, project: &Project) -> Result<(), String> {
            self.ensured
                .borrow_mut()
                .push(project.connect_session_name.clone());
            if self.ensure_failures.contains(&project.connect_session_name) {
                Err(format!("ensure failed: {}", project.connect_session_name))
            } else {
                Ok(())
            }
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
            port.attached.borrow()[0].0,
            PathBuf::from("/home/me/dev/tonys-blog")
        );
        assert_eq!(port.attached.borrow()[0].1, "tonys-blog");
    }

    #[test]
    fn projects_json_uses_null_layout_by_default() {
        let port = FakePort::new(vec!["/home/me/dev/tonys-nix"]);
        let value: serde_json::Value =
            serde_json::from_str(&projects_json(&port).unwrap()).unwrap();
        assert_eq!(value[0]["layout"], serde_json::Value::Null);
        assert_eq!(value[0]["session_name"], "tonys-nix");
    }

    #[test]
    fn central_layout_mapping_accepts_canonical_path_or_name() {
        let mut port = FakePort::new(vec!["/home/me/dev/api"]);
        port.layouts.insert("api".into(), "backend".into());
        let value: serde_json::Value =
            serde_json::from_str(&projects_json(&port).unwrap()).unwrap();
        assert_eq!(value[0]["layout"], "backend");
    }

    #[test]
    fn normalized_name_collisions_get_stable_distinct_suffixes() {
        let port = FakePort::new(vec!["/work/one/api service", "/work/two/api@service"]);
        let value = projects(&port).unwrap();
        assert_ne!(value[0].session_name, value[1].session_name);
        assert!(value
            .iter()
            .all(|project| project.session_name.starts_with("api-service-")));
    }

    #[test]
    fn canonical_paths_are_deduplicated() {
        let port = FakePort::new(vec!["/home/me/dev/api", "/home/me/dev/api"]);
        assert_eq!(projects(&port).unwrap().len(), 1);
    }

    #[test]
    fn collision_adds_hashes_only_when_needed() {
        let alone = FakePort::new(vec!["/work/one/api service"]);
        let with_collision = FakePort::new(vec!["/work/one/api service", "/work/two/api@service"]);
        let alone_name = projects(&alone).unwrap()[0].session_name.clone();
        let together_name = projects(&with_collision)
            .unwrap()
            .into_iter()
            .find(|project| project.path == PathBuf::from("/work/one/api service"))
            .unwrap()
            .session_name;
        assert_eq!(alone_name, "api-service");
        assert_ne!(alone_name, together_name);
    }

    #[test]
    fn stable_session_name_fits_the_macos_unix_socket_budget() {
        let port = FakePort::new(vec![
            "/home/me/dev/a-project-name-that-is-much-longer-than-the-socket-budget",
        ]);
        let project = projects(&port).unwrap().remove(0);
        assert!(project.session_name.len() <= 24);
        assert!(project
            .session_name
            .ends_with(&format!("-{:08x}", stable_path_hash(&project.path))));
    }

    #[test]
    fn unique_active_legacy_session_is_reused_during_rollout() {
        let mut port = FakePort::new(vec!["/home/me/dev/api"]);
        port.active_sessions.insert("api".into());
        let project = projects(&port).unwrap().remove(0);
        assert_eq!(project.session_name, "api");
        assert_eq!(project.connect_session_name, "api");
    }

    #[test]
    fn inactive_unique_project_connects_to_plain_basename_session() {
        let port = FakePort::new(vec!["/home/me/dev/api"]);
        let project = projects(&port).unwrap().remove(0);
        assert_eq!(project.connect_session_name, project.session_name);
    }

    #[test]
    fn unique_project_reuses_active_hash_until_that_session_exits() {
        let mut port = FakePort::new(vec!["/work/one/api"]);
        let hash_name = format!("api-{:08x}", stable_path_hash(Path::new("/work/one/api")));
        port.active_sessions.insert(hash_name.clone());
        let project = projects(&port).unwrap().remove(0);
        assert_eq!(project.session_name, "api");
        assert_eq!(project.connect_session_name, hash_name);
        assert_eq!(project.naming_conflict, None);
    }

    #[test]
    fn ambiguous_active_basename_blocks_hashed_collision_creation() {
        let mut port = FakePort::new(vec!["/work/one/api", "/work/two/api"]);
        port.active_sessions.insert("api".into());
        let projects = projects(&port).unwrap();
        assert!(projects.iter().all(|project| {
            project.connect_session_name == project.session_name
                && project.naming_conflict.as_deref().is_some_and(|err| {
                    err.contains("close it before creating hashed collision sessions")
                })
        }));
    }

    #[test]
    fn auto_project_matches_project_descendants_only() {
        struct AutoPort {
            inner: FakePort,
            cwd: PathBuf,
        }
        impl RepoPort for AutoPort {
            fn repo_dirs(&self) -> Result<Vec<PathBuf>, String> {
                self.inner.repo_dirs()
            }
            fn canonicalize_repo(&self, path: &Path) -> Result<PathBuf, String> {
                Ok(path.to_path_buf())
            }
            fn project_layouts(&self) -> Result<BTreeMap<String, String>, String> {
                self.inner.project_layouts()
            }
            fn active_sessions(&self) -> Result<BTreeSet<String>, String> {
                self.inner.active_sessions()
            }
            fn select_repo(&self, candidates: &str) -> Result<Option<String>, String> {
                self.inner.select_repo(candidates)
            }
            fn current_dir(&self) -> Result<PathBuf, String> {
                Ok(self.cwd.clone())
            }
            fn ensure_project_session(&self, project: &Project) -> Result<(), String> {
                self.inner.ensure_project_session(project)
            }
            fn launch_project_session(&self, project: &Project) -> Result<u8, String> {
                self.inner.launch_project_session(project)
            }
            fn log(&self, message: &str) {
                self.inner.log(message)
            }
        }
        let inside = AutoPort {
            inner: FakePort::new(vec!["/home/me/dev/api"]),
            cwd: "/home/me/dev/api/src".into(),
        };
        assert_eq!(auto_project(&inside).unwrap(), 0);
        assert_eq!(
            inside.inner.attached.borrow()[0].0,
            PathBuf::from("/home/me/dev/api")
        );

        let outside = AutoPort {
            inner: FakePort::new(vec!["/home/me/dev/api"]),
            cwd: "/home/me/dev".into(),
        };
        assert_eq!(auto_project(&outside).unwrap(), 2);
        assert!(outside.inner.attached.borrow().is_empty());
    }

    #[test]
    fn auto_project_delegates_only_the_selected_project_to_the_launch_port() {
        struct InsidePort {
            inner: FakePort,
        }
        impl RepoPort for InsidePort {
            fn repo_dirs(&self) -> Result<Vec<PathBuf>, String> {
                self.inner.repo_dirs()
            }
            fn canonicalize_repo(&self, path: &Path) -> Result<PathBuf, String> {
                Ok(path.to_path_buf())
            }
            fn project_layouts(&self) -> Result<BTreeMap<String, String>, String> {
                self.inner.project_layouts()
            }
            fn active_sessions(&self) -> Result<BTreeSet<String>, String> {
                self.inner.active_sessions()
            }
            fn select_repo(&self, candidates: &str) -> Result<Option<String>, String> {
                self.inner.select_repo(candidates)
            }
            fn current_dir(&self) -> Result<PathBuf, String> {
                Ok(PathBuf::from("/home/me/dev/api/src"))
            }
            fn ensure_project_session(&self, project: &Project) -> Result<(), String> {
                self.inner.ensure_project_session(project)
            }
            fn launch_project_session(&self, project: &Project) -> Result<u8, String> {
                self.inner.launch_project_session(project)
            }
            fn log(&self, message: &str) {
                self.inner.log(message)
            }
        }

        let port = InsidePort {
            inner: FakePort::new(vec!["/home/me/dev/api"]),
        };
        assert_eq!(auto_project(&port).unwrap(), 0);
        assert_eq!(port.inner.attached.borrow().len(), 1);
    }

    #[test]
    fn repo_to_rejects_ambiguous_display_names() {
        let port = FakePort::new(vec!["/work/one/api", "/work/two/api"]);
        let err = run_to(&port, "api").unwrap_err();
        assert!(err.contains("ambiguous repo name: api"));
        assert!(err.contains("/work/one/api"));
        assert!(err.contains("/work/two/api"));
        assert!(port.attached.borrow().is_empty());
    }

    #[test]
    fn repo_to_rejects_path_like_names() {
        let port = FakePort::new(vec!["/home/me/dev/tonys-blog"]);
        assert!(run_to(&port, "../tonys-blog")
            .unwrap_err()
            .contains("invalid repo name"));
        assert!(port.attached.borrow().is_empty());
    }

    #[test]
    fn repo_picker_cancel_exits_successfully_without_attach() {
        let port = FakePort::new(vec!["/home/me/dev/tonys-blog"]);
        assert_eq!(run(&port).unwrap(), 0);
        assert!(port.attached.borrow().is_empty());
    }

    #[test]
    fn repo_picker_attaches_selected_directory_with_sanitized_session() {
        let port = FakePort::new(vec!["/home/me/dev/tonys blog"])
            .with_selection("/home/me/dev/tonys blog");
        assert_eq!(run(&port).unwrap(), 0);
        assert_eq!(port.attached.borrow()[0].1, "tonys-blog");
    }

    #[test]
    fn reload_projects_ensures_every_discovered_project_without_launching() {
        let port = FakePort::new(vec!["/work/api", "/work/web"]);
        assert_eq!(reload_projects(&port).unwrap(), 0);
        assert_eq!(port.ensured.borrow().len(), 2);
        assert!(port.attached.borrow().is_empty());
    }

    #[test]
    fn reload_projects_continues_after_failures_and_aggregates_them() {
        let port = FakePort::new(vec!["/work/api", "/work/web"]).with_ensure_failure("api");
        let err = reload_projects(&port).unwrap_err();
        assert!(err.contains("api"));
        assert_eq!(port.ensured.borrow().as_slice(), &["api", "web"]);
    }

    #[test]
    fn reload_projects_skips_conflicted_projects_but_reports_the_conflict() {
        let mut port = FakePort::new(vec!["/one/api", "/two/api"]);
        port.active_sessions.insert("api".into());
        let err = reload_projects(&port).unwrap_err();
        assert!(err.contains("ambiguous active project session"));
        assert!(port.ensured.borrow().is_empty());
    }
}
