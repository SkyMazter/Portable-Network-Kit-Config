use clap::Parser;
use std::io::{self, Error, ErrorKind, Write};
use std::net::{SocketAddr, TcpStream};
use std::process::{Command, ExitStatus, Output, Stdio, exit};
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

fn run_bash_script(path: &str) -> Result<ExitStatus, Error> {
    let script = Command::new("sh")
        .arg("-c")
        .arg("bash")
        .arg(path)
        .stdout(Stdio::inherit())
        .output()?;
    let output = script.status.success();

    if output {
        Ok(script.status)
    } else {
        let error_msg: Error = Error::new(
            ErrorKind::Other,
            format!(
                ">>> Command failed with status: {}. Stderr: {}",
                script.status,
                String::from_utf8_lossy(&script.stderr)
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

fn get_file_location(file_name: &str, home_path: &str) -> String {
    let script_location: String;

    match run_command("find", Some(&vec![home_path, "-name", file_name])) {
        Ok(output) => {
            script_location = String::from_utf8_lossy(&output.stdout).trim().to_string();
        }
        Err(e) => {
            eprintln!("{}", e);
            eprintln!(
                ">>> Unable to locate the nessecary install scripts, please ensure they are downloaded onto your machine..."
            );
            exit(1)
        }
    }

    return script_location;
}

fn install_docker_container(service: &str, path: &str) -> bool {
    let file_name: String = format!("{}_installation.sh", service);
    let path: String = get_file_location(file_name.as_str().trim(), path);
    match run_bash_script(path.as_str()) {
        Ok(_) => {
            return true;
        }
        Err(e) => {
            eprintln!("{}", e);
            return false;
        }
    }
}

fn main() {
    let cli: Cli = Cli::parse();
    let cmd: &str = "figlet";
    let args: Vec<&str> = vec!["PNK Configuration", "-f", "mini"];

    match run_command(cmd, Some(&args)) {
        Ok(output) => {
            let msg: String = String::from_utf8_lossy(&output.stdout).to_string();
            println!("{}", msg)
        }
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

    let home_path: String = format!("/home/{}/Portable-Network-Kit-Config", username.trim());

    let script_location = get_file_location("docker_install.sh", home_path.as_str());

    match run_command("which", Some(&vec!["docker"])) {
        Ok(output) => {
            if output.status.success() {
                println!(">>> Docker is installed, proceeding with the install")
            }
        }

        Err(e) => {
            eprintln!("{}", e);
            if prompt_yes_no("Would you like to run the docker install script?").unwrap() {
                match run_bash_script(script_location.as_str()) {
                    Ok(_) => println!("\n>>> Docker is succesfully installed..."),
                    Err(e) => {
                        eprintln!("{}", e);
                        eprintln!(
                            ">>> Unable to locate the nessecary install scripts, please ensure they are downloaded onto your machine..."
                        );
                        exit(1)
                    }
                }
            } else {
                eprintln!(
                    ">>> Docker is required for the PNK to run is applications, closing script..."
                );
                exit(1)
            }
        }
    }

    let docker_services: Vec<&str> = vec!["wordpress", "matrix", "owncloud", "etherpad"];
    for service in docker_services {
        if install_docker_container(service, home_path.as_str()) {
            print!("some")
        } else {
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
