#!/usr/bin/bash

echo "#####___Installing pnk-config dependancies___#####"
echo ""
sudo apt-get install figlet

echo "#####___Compiling pnk-config command___#####"
echo ""
g++ pnk-config/pnk-config.cpp -o pnk-config/pnk-config

sudo cp pnk-config/pnk-config /usr/local/bin/

echo "#####___Install Complete___#####"
echo ""
echo "--> Try running 'pnk-config' to verify"
