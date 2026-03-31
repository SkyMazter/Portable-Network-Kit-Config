#!/usr/bin/bash

echo "#####___Installing pnk-conf command___#####" \n
sudo rm /usr/bin/local/pnk-conf

g++ pnk-config/pnk-conf.cpp -o pnk-conf

sudo cp pnk-conf /usr/local/bin/