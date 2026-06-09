use clap::Parser;
use std::io::{Error, ErrorKind};
use std::net::{SocketAddr, TcpStream};
use std::process::{Command, Output, Stdio, exit};

use std::time::Duration;

#[derive(Parser)]
#[command(name = "pnk-update")]
#[command(version = "1.0")]
#[command(about = "Updates the PNK CLI suite via the GitHub Repository", long_about = None)]
struct Cli {
    #[arg(short, long, default_value_t = 5000)]
    timeout: u32,
}

fn check_internet_conenction(timeout_ms: u32) -> bool {
    let addr = SocketAddr::from(([140, 82, 112, 4], 80));

    match TcpStream::connect_timeout(&addr, Duration::from_millis(timeout_ms as u64)) {
        Ok(_) => true,
        Err(_) => false,
    }
}

fn check_for_service(service_name: &str) -> bool {
    match Command::new("sh")
        .arg("-c")
        .arg(format!("dpkg -l {}", service_name))
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
    {
        Ok(child_process) => {
            let output = child_process
                .wait_with_output()
                .expect("Failed to wait for child process");
            if output.status.success() && !output.stdout.is_empty() {
                println!(
                    ">> {} is installed. Exited with code {} \n",
                    service_name, output.status
                );
                return true;
            } else {
                println!(
                    ">> {} is not installed. Exited with code {} \n",
                    service_name, output.status
                );
                return false;
            }
        }

        Err(e) => {
            eprintln!("Failed to run command: {}", e);
            return false;
        }
    }
}

fn pull_git_changes(dir: &str) {
    match Command::new("git")
        .arg("-C")
        .arg(dir)
        .arg("pull")
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
    {
        Ok(child_process) => {
            let output = child_process
                .wait_with_output()
                .expect("Unable to retrieve output.");
            match output.status.code().unwrap() {
                0 => println!(">> Succesfully pulled code from git repository\n"),
                1 => println!(">> Unable to pull code due to error noted above.\n"),
                _ => {
                    println!(
                        ">> Error, Exited with code: {} \n",
                        output.status.code().unwrap()
                    );
                    exit(output.status.code().unwrap());
                }
            }
        }
        Err(e) => {
            eprintln!("Failed to run command: {}", e);
            exit(1);
        }
    }
}

fn install_cargo_script(dir: &str) {
    match Command::new("cargo")
        .arg("install")
        .arg("--path")
        .arg(dir)
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
    {
        Ok(child_process) => {
            let output = child_process
                .wait_with_output()
                .expect("Unable to retrieve output.");
            match output.status.success() {
                true => println!(">> Succesfully installed script\n"),
                false => exit(output.status.code().unwrap()),
            }
        }
        Err(e) => {
            println!("Error: {}", e);
            exit(1);
        }
    }
}

fn run_command(cmd: &str, args: Option<&[&str]>) -> Result<Output, Error> {
    let mut command = Command::new(cmd);

    match args {
        Some(args) => {
            for arg in args {
                command.arg(arg);
            }
        }
        None => {}
    }

    let output = command.output()?;

    if output.status.success() {
        return Ok(output);
    } else {
        let error_msg: Error = Error::new(
            ErrorKind::Other,
            format!(
                ">>> Command failed with status: {}. Stderr: {}",
                output.status,
                String::from_utf8_lossy(&output.stderr)
            ),
        );
        return Err(error_msg);
    }
}

fn main() {
    let cli = Cli::parse();
    println!(
        ">> Running internet check with {:?}ms timeout...\n",
        cli.timeout
    );
    let timeout_ms = cli.timeout;

    if !check_internet_conenction(timeout_ms) {
        println!(">> Unable to connect to the internet! \n");
        return;
    }

    let username: String;
    match run_command("whoami", None) {
        Ok(output) => {
            username = String::from_utf8_lossy(&output.stdout).to_string();
        }
        Err(e) => {
            eprintln!("{}", e);
            exit(1);
        }
    }

    println!(">> There is internet! \n");

    if !check_for_service("git") {
        println!(">> Unable to continue update, missing dependancy: Git");
        return;
    }

    let mut dir: String = format!("/home/{}/Portable-Network-Kit-Config", username.trim());

    pull_git_changes(&dir);

    dir = format!(
        "/home/{}/Portable-Network-Kit-Config/CLI_Tools/pnk-update/",
        username.trim()
    );
    install_cargo_script(&dir);
    println!(">> pnk-config has been recompiled...\n");
    dir = format!(
        "/home/{}/Portable-Network-Kit-Config/CLI_Tools/pnk-config/",
        username.trim()
    );
    install_cargo_script(&dir);
    println!(">> pnk-config has been recompiled...\n");
    println!(">> Update Complete!\n")
}
