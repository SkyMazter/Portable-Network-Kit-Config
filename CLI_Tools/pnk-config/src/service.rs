use std::process::{Command, Stdio};

pub fn get_service_stat() {
    let output = Command::new("ls")
        .args("-l")
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .expect("Failed to run command");
    if output.status.success() {
        println!("{}", String::from_utf8_lossy(&output.stdout));
    }
}
