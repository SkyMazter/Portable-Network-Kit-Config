#!/usr/bin/bash

echo "#####___Installing pnk-config dependancies___#####"
echo ""
sudo apt-get install figlet

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"

echo "#####___Compiling pnk-config command___#####"
echo ""
# g++ pnk-config/pnk-config.cpp -o pnk-config/pnk-config

# sudo cp pnk-config/pnk-config /usr/local/bin/
LOCAL_USER=$(whoami)
INSTALL_PATH="/home/${LOCAL_USER}/Portable-Network-Kit-Config/CLI_Tools/pnk-config"
cargo install --path "$INSTALL_PATH"

INSTALL_PATH="/home/${LOCAL_USER}/Portable-Network-Kit-Config/CLI_Tools/pnk-update"
cargo install --path "$INSTALL_PATH"

echo "#####___Install Complete___#####"
echo ""
echo "--> Try running 'pnk-config' to verify"
