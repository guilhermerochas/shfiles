#!/bin/bash

############################
# Creator: Guilherme Rocha
############################

echo "Name of your emulator: "
read emulator

droid=~/.android/avd/${emulator}.avd/
count=(`find ${droid} -maxdepth 1 -name "*.lock"`)
sudo chmod 777 /dev/kvm
if [[ ${#count[@]} -gt 0 ]]; then 
    rm ${droid}/*.lock
fi
~/Android/Sdk/emulator/emulator -avd $emulator &>/dev/null &

