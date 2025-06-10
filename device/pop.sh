#!/bin/bash

#Usage: 
#/ROOT/device3/pop.sh
#/opt/5G-SafeKey/device3/pop.sh

echo $(sudo head -n 1 /mnt/5G-SafeKey/device3/secret-keys.csv) | sudo tee /mnt/5G-SafeKey/device3/next.txt >> /dev/null
sudo sed -i '1d' /mnt/5G-SafeKey/device3/secret-keys.csv
