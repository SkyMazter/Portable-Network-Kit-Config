use clap::Parser;
use std::process::{Command, Stdio};

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    #[arg(short, long)]
    service: Option<String>,
}

fn main() {
    let cli: Cli = Cli::parse();

    match Command::new("figlet")
        .args(["PNK Configuration", "-f", "mini"])
        .stderr(Stdio::piped())
        .stdout(Stdio::inherit())
        .output()
    {
        Ok(_) => println!("_|_|_"),
        Err(e) => eprintln!("Error: {}", e),
    }

    if cli.service != None {
        println!(">> Searching for {} container...", cli.service.unwrap())
    }

    //Run Figlet
    //Check for internet connection
    //Check for bash scripts
    // check if docker is installed
    //  install docker if not installed
    // check if docker containers are running
    //  install images if not installed, start containers if not running
}
