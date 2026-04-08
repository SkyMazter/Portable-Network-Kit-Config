#!/usr/bin/bash

echo "#####___Installing pnk-conf dependancies___#####"

sudo apt-get figlet

echo "#####___Compiling pnk-conf command___#####"

g++ pnk-config/pnk-conf.cpp -o pnk-config/pnk-conf

sudo cp pnk-config/pnk-conf /usr/local/bin/

echo "#####___Install Complete___#####"
echo "--> Try running 'pnk-conf' to verify"
