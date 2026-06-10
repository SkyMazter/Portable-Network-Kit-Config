# Portable-Network-Kit-Config

The PNK (Portable Network Kit) v4 software image by Community Tech NY is a custom-built platform for creating portable, offline mesh networks. It provides essential tools and resources to support community connectivity and information-sharing, even in areas without internet access. This version enhances stability, simplifies setup, and includes pre-configured open-source applications, making it easy for users to deploy localized, resilient networks for community-driven communication and data sharing. This is a program written by Oscar Comunidad(SkyMazter) to serve as an installer fro the server program that runs a PNK.

## Table of Contents

1. [Installation](#installation)
2. [Usage](#usage)
3. [License](#license)

## Installation

Steps to install the program:

1. **Install Git:**
   - Install Git onto the Raspberry Pi using the following command:
     ```sh
     sudo apt update && sudo apt install git -y
     ```

2. **Clone the Repository:**
   - Clone the repository using Git:
     ```sh
     git clone https://github.com/SkyMazter/Portable-Network-Kit-Config.git
     ```

3. **Execute Setup Script:**
   - Navigate into the cloned directory and execute the setup script:

     ```sh
     cd Portable-Network-Kit-Config/CLI_Tools

     bash install_cli_tools.sh
     ```

## Usage

By running the following command you will be prompted to install the required apps and dependancies.

```sh
pnk-config
```

In order to keep up with the latest version of this installer, run the following command to update the program

```sh
pnk-update
```

### App Ports

The applications can be accessed locally via the following ports:

- **WordPress:** http://<You_hostname>/
- **Unifi:** https://<You_hostname>:11443/
- **Etherpad:** http://<You_hostname>:9001/
- **Cinny:** http://<You_hostname>:9002/
- **Owncloud:** http://<You_hostname>:9003/

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
