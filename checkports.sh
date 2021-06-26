#!/bin/bash

if (( $EUID != 0 )); then
   echo "you must run this as root to check the ports"
   exit
fi

process_id=($(netstat -tulpn | grep -i "listen" | awk '{ print $7 }' | grep -oP '^((\d+)[^\/])'))

echo "Showing the running processes on listening ports:"
echo  

for id in ${process_id[@]}; do
   process=$(ps -aux | awk -v id=$id '$2 ~ id' | head -n 1 | awk '{ print $11 }')
   echo "$process -> PID: $id"  
done