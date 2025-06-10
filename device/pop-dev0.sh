#!/bin/bash

#Usage: 
#/ROOT/device0/pop.sh <device n> ..
#/opt/5G-SafeKey/device0/pop.sh 1 2

if [ -z "$1" ]; then
 echo "Enter the device ids you want to detect. Ex. 3005 3006 3007"
 exit 1
fi 

for i in "$@"
do
  sudo echo $(head -n 1 /mnt/5G-SafeKey/device0/device"$i"_secret-keys.csv) | sudo tee /mnt/5G-SafeKey/device0/device"$i"_next.txt >> /dev/null
  sudo sed -i '1d' /mnt/5G-SafeKey/device0/device"$i"_secret-keys.csv
done
