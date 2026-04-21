use std::net::{SocketAddr, TcpStream};
use std::process::{Command, Stdio, exit};
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

fn main() {
    let timeout_ms = 5000;

    if !check_internet_conenction(timeout_ms) {
        println!(">> Unable to connect to the internet! \n");
        return;
    }
    println!(">> There is internet! \n");

    if !check_for_service("git") {
        println!(">> Unable to continue update, missing dependancy: Git");
        return;
    }

    let mut dir = "/home/admin/Portable-Network-Kit-Config/";
    pull_git_changes(dir);

    dir = "/home/admin/Portable-Network-Kit-Config/CLI_Tools/pnk-update/";
    install_cargo_script(dir);

    println!(">> Update Complete!\n")
}
