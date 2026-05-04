use clap::Parser;
use std::io::{self, Error, ErrorKind, Write};
use std::net::{SocketAddr, TcpStream};
use std::process::{Command, Output, exit};
use std::time::Duration;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    #[arg(short, long)]
    service: Option<String>,
}

fn check_internet_connection(timeout_ms: u32) -> bool {
    let addr = SocketAddr::from(([140, 82, 112, 4], 80));
    match TcpStream::connect_timeout(&addr, Duration::from_millis(timeout_ms as u64)) {
        Ok(_) => true,
        Err(_) => false,
    }
}

fn run_command(cmd: &str, args: Option<&[&str]>) -> Result<Output, std::io::Error> {
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

fn prompt_yes_no(prompt: &str) -> Option<bool> {
    print!(">>> {} (y/N): ", prompt);
    io::stdout().flush().expect(">>> Failed to flush stdout");

    let mut input = String::new();

    match io::stdin().read_line(&mut input) {
        Ok(_) => {
            let trimmed_input = input.trim().to_lowercase();
            match trimmed_input.as_str() {
                "y" => Some(true),
                "n" => Some(false),
                "" => None,
                _ => {
                    eprintln!(">>> Error: Invalid input");
                    None
                }
            }
        }
        Err(e) => {
            eprintln!(">>> I/O Error while reading input: {}", e);
            None
        }
    }
}

fn main() {
    let cli: Cli = Cli::parse();
    let cmd: &str = "figlet";
    let mut args: Vec<&str> = vec!["PNK Configuration", "-f", "mini"];

    match run_command(cmd, Some(&args)) {
        Ok(_) => {}
        Err(e) => {
            eprintln!("{}", e)
        }
    }

    if cli.service != None {
        println!(">>> Searching for {} container...", cli.service.unwrap())
    }

    match check_internet_connection(5000) {
        true => println!(">>> Internet connection found...\n"),
        false => return,
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

    let path: String = format!("/home/{}", username.trim());

    let script_location: String;
    args = vec![&path, "-name", "docker_install.sh"];
    match run_command("find", Some(&args)) {
        Ok(output) => {
            script_location = String::from_utf8_lossy(&output.stdout).to_string();
            println!(">>> {}", script_location);
        }
        Err(e) => {
            eprintln!("{}", e);
            eprintln!(
                ">>> Unable to locate the nessecary install scripts, please ensure they are downloaded onto your machine..."
            );
            exit(1)
        }
    }
    println!("...{}...", script_location);
    args = vec!["docker"];
    match run_command("which", Some(&args)) {
        Ok(output) => {
            if output.status.success() {
                println!(">>> Docker is installed, proceeding with the install")
            }
        }

        Err(e) => {
            eprintln!("{}", e);
            if prompt_yes_no("Would you like to run the docker install script?").unwrap() {
                match run_command("bash", Some(&vec![script_location.as_str()])) {
                    Ok(_) => println!(">>> Docker is succesfully installed..."),
                    Err(e) => {
                        eprintln!("{}", e);
                        eprintln!(
                            ">>> Unable to locate the nessecary install scripts, please ensure they are downloaded onto your machine..."
                        );
                        exit(1)
                    }
                }
            } else {
                exit(1)
            }
        }
    }

    //Run Figlet
    //Check for internet connection
    //Check for bash scripts
    // check if docker is installed
    //  install docker if not installed
    // check if docker containers are running
    //  install images if not installed, start containers if not running
}
