use std::collections::BTreeMap;

use zellij_tile::prelude::*;

#[derive(Default)]
struct NavSwitcher {
    pending_target: Option<BTreeMap<String, String>>,
}

register_plugin!(NavSwitcher);

impl ZellijPlugin for NavSwitcher {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        if configuration.contains_key("session") {
            self.pending_target = Some(configuration);
        }
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if pipe_message.name != "zellij-nav-switch" {
            return false;
        }

        let result = switch_from_args(&pipe_message.args);
        if let PipeSource::Cli(pipe_id) = pipe_message.source {
            cli_pipe_output(&pipe_id, result);
            unblock_cli_pipe_input(&pipe_id);
        }

        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {
        if let Some(target) = self.pending_target.take() {
            switch_from_args(&target);
        }
    }
}

fn switch_from_args(args: &BTreeMap<String, String>) -> &'static str {
    let Some(session) = args.get("session").filter(|value| !value.is_empty()) else {
        return "error:missing-session";
    };

    match args.get("kind").map(String::as_str).unwrap_or("session") {
        "session" => {
            switch_session(Some(session));
            "ok:session"
        }
        "tab" => {
            let tab_position = parse_optional_usize(args.get("tab_id"));
            if tab_position.is_none() {
                return "error:missing-tab";
            }
            switch_session_with_focus(session, tab_position, None);
            "ok:tab"
        }
        "pane" => {
            let tab_position = parse_optional_usize(args.get("tab_id"));
            let pane_id = parse_optional_u32(args.get("pane_id"));
            if pane_id.is_none() {
                return "error:missing-pane";
            }
            switch_session_with_focus(session, tab_position, pane_id.map(|id| (id, false)));
            "ok:pane"
        }
        _ => "error:unknown-kind",
    }
}

fn parse_optional_usize(value: Option<&String>) -> Option<usize> {
    value
        .filter(|raw| !raw.is_empty() && raw.as_str() != "-")
        .and_then(|raw| raw.parse::<usize>().ok())
}

fn parse_optional_u32(value: Option<&String>) -> Option<u32> {
    value
        .filter(|raw| !raw.is_empty() && raw.as_str() != "-")
        .and_then(|raw| raw.parse::<u32>().ok())
}
