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

fn check_for_service(service_name: &str) {
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
                .expect("Failed to wait fro child process");
            if output.status.success() && !output.stdout.is_empty() {
                println!("{} is installed.", service_name);
            } else {
                println!("{} is not installed.", service_name);
            }
        }

        Err(e) => eprintln!("Failed to run command: {}", e),
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

    check_for_service("docker.service");
}
