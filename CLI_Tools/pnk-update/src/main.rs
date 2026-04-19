use std::net::{SocketAddr, TcpStream};
use std::process::{Command, Stdio};
use std::time::Duration;

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
        .arg(format!(
            "systemctl list list-unit-files --type=service | grep {}",
            service_name
        ))
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
    {
        Ok(child_process) => {
            let output = child_process
                .wait_with_output()
                .expect("Failed to wait for child process");
            if output.status.success() && !output.stdout.is_empty() {
                println!(
                    "{} is installed. Exited with code {}",
                    service_name, output.status
                );
                return true;
            } else {
                println!(
                    "{} is not installed. Exited with code {}",
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
            let output = child_process.wait_with_output().expect("msg");
            match output.status.code().unwrap() {
                0 => println!("Succesfully pulled code from git repository"),
                1 => println!(
                    "Unable to pull code due to local changes made to the repository, please undo any changes made to the code."
                ),
                _ => println!("Error, Exited with code: {}", output.status.code().unwrap()),
            }
        }
        Err(e) => {
            eprintln!("Failed to run command: {}", e);
        }
    }
}

fn main() {
    // check for dependancies
    // return if not installed
    //
    // check for internet connection
    //
    // check for connection to github repo
    // run git pull
    // compile the new versions of the cli commands
    // add it to the /usr/local/bin/ directory
    let timeout_ms = 5000;

    if check_internet_conenction(timeout_ms) {
        println!("There is internet!");
    } else {
        println!("Unable to connect to the internet!");
    }

    // if check_for_service("git") {

    // }
    //
    let dir = "/Users/oscar/Documents/CodingProjects/Projects/Portable-Network-Kit-Config/";
    pull_git_changes(dir);
}
