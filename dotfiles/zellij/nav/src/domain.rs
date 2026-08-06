use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TargetKind {
    Session,
    Tab,
    Pane,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Target {
    pub kind: TargetKind,
    pub session: String,
    pub tab_id: Option<u32>,
    pub pane_id: Option<u32>,
    #[serde(default)]
    pub label: String,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]
pub struct Location {
    pub session: String,
    pub tab_id: Option<u32>,
    pub pane_id: Option<u32>,
    pub label: String,
}

impl Target {
    pub fn kind_name(&self) -> &'static str {
        match self.kind {
            TargetKind::Session => "session",
            TargetKind::Tab => "tab",
            TargetKind::Pane => "pane",
        }
    }

    pub fn valid(&self) -> bool {
        if self.session.is_empty() {
            return false;
        }

        match self.kind {
            TargetKind::Session => self.tab_id.is_none() && self.pane_id.is_none(),
            TargetKind::Tab => self.tab_id.is_some() && self.pane_id.is_none(),
            TargetKind::Pane => self.tab_id.is_some() && self.pane_id.is_some(),
        }
    }

    pub fn validation_reason(&self) -> &'static str {
        if self.session.is_empty() {
            return "missing-session";
        }

        match self.kind {
            TargetKind::Session if self.tab_id.is_some() => "session-has-tab-id",
            TargetKind::Session if self.pane_id.is_some() => "session-has-pane-id",
            TargetKind::Tab if self.tab_id.is_none() => "invalid-tab-id",
            TargetKind::Tab if self.pane_id.is_some() => "tab-has-pane-id",
            TargetKind::Pane if self.tab_id.is_none() => "invalid-tab-id",
            TargetKind::Pane if self.pane_id.is_none() => "invalid-pane-id",
            _ => "unknown",
        }
    }

    pub fn from_location(location: Location) -> Self {
        let kind = if location.pane_id.is_some() {
            TargetKind::Pane
        } else if location.tab_id.is_some() {
            TargetKind::Tab
        } else {
            TargetKind::Session
        };

        Self {
            kind,
            session: location.session,
            tab_id: location.tab_id,
            pane_id: location.pane_id,
            label: location.label,
        }
    }

    pub fn matches_location(&self, location: &Location) -> bool {
        if self.session != location.session {
            return false;
        }

        match self.kind {
            TargetKind::Session => true,
            TargetKind::Tab => self.tab_id == location.tab_id,
            TargetKind::Pane => self.pane_id == location.pane_id,
        }
    }

    pub fn summary(&self) -> String {
        serde_json::json!({
            "kind": self.kind_name(),
            "session": self.session,
            "tab_id": self.tab_id,
            "pane_id": self.pane_id,
        })
        .to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn target(kind: TargetKind, tab_id: Option<u32>, pane_id: Option<u32>) -> Target {
        Target {
            kind,
            session: "work".to_string(),
            tab_id,
            pane_id,
            label: "work".to_string(),
        }
    }

    #[test]
    fn target_schema_matches_bash_contract() {
        assert!(target(TargetKind::Session, None, None).valid());
        assert!(target(TargetKind::Tab, Some(0), None).valid());
        assert!(target(TargetKind::Pane, Some(0), Some(7)).valid());

        assert!(!target(TargetKind::Session, Some(0), None).valid());
        assert!(!target(TargetKind::Tab, None, None).valid());
        assert!(!target(TargetKind::Pane, Some(0), None).valid());
    }

    #[test]
    fn summary_matches_bash_json_shape() {
        assert_eq!(
            target(TargetKind::Pane, Some(0), Some(7)).summary(),
            r#"{"kind":"pane","pane_id":7,"session":"work","tab_id":0}"#
        );
    }
}
