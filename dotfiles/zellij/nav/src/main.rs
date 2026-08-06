mod cli;
mod domain;
mod feature;
mod outbound;

use std::process::ExitCode;

fn main() -> ExitCode {
    cli::run(std::env::args().collect())
}
