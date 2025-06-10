#!/bin/bash

#Target X Safelogin installer
INSTALLER_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
export INSTALLER_DIR

source $INSTALLER_DIR/scripts/cecho.sh
source $INSTALLER_DIR/config-safelogin.txt
#set -e

function main()
{
echo
  echo "${BCYAN}${SLINE}Target X SafeLogin Installer v$version${SET}"
  echo
  if [[ $USER == root ]]; then
     cecho "This script must not run as root" $red 1>&2
     exit 1
  fi

  cecho "Reading config.txt.."  $yellow
  echo "Device name: $device_name"
  echo "Device description: $device_description"
  echo "Device UUID: $device_uuid"
  if [ -z "$device_name" ] && [ -z "$device_uuid" ]; then
     echo "Please enter a device name to register new device or existing UUID (if known)"
     exit 1
  fi
  echo "Server protocol: $server_protocol"
  echo "Server host: $server_host"
  echo "Server port: $server_port"
  echo "Self-signed SSL certificate: $self_signed"
  echo -n "${BOLD}If all fields are set correctly, press enter to continue installation.. ${SET}"
  read agree

  cecho "Ensuring system is up to date.."  $yellow
  sudo apt-get update -y
  cecho "System is up to date." $blue

  cecho "Upgrading the system.." $yellow
  sudo apt-get upgrade -y
  cecho "System upgraded." $blue

  cecho "Installing required packages..." $yellow
  sudo apt install zip -y
  sudo apt install jq -y
  sudo apt install cmake -y
  sudo apt-get install libcurl4-openssl-dev -y
  sudo apt-get install cryptsetup -y
  sudo apt-get install libcryptsetup-dev -y
  cecho "Required packages installed!" $blue

  cecho "Initializing disk..." $yellow
  #sudo mkdir -p /mnt
  sudo mkdir -p /opt/safelogin

#  lsblk
#  echo -n "${BOLD}Enter disk name: ${SET}"
#  read diskName
  #sda1

#  cecho "Checking existing mounts..." $yellow
#  get_mount=$(df -h | grep $diskName | awk '{ print $6 }')
#  if [ ! -z "$get_mount" ]; then
#    sudo umount $get_mount
#    echo "Unmounted "$get_mount
#  fi
#  cecho "Mount checked" $blue


  #diskKey=$(curl -u "$user:$password" -X GET "$server_protocol://$server_host:$server_port/safekey/diskKey?uuid=$device_uuid")
  #https://target-x.i46.io/safekey/diskKey?uuid=
  #echo $diskKey
  #echo "Copy and paste the diskKey to encrypt the disk!"

  if [ $self_signed -eq 1 ]; then
    storageKey=$(curl -k -u "$user:$password" -X GET "$server_protocol://$server_host:$server_port/safekey/storageKey?uuid=$device_uuid" | jq -r .storageKey)
  else
    storageKey=$(curl -u "$user:$password" -X GET "$server_protocol://$server_host:$server_port/safekey/storageKey?uuid=$device_uuid" | jq -r .storageKey)
  fi
  #https://target-x.i46.io/safekey/storageKey?uuid=
  echo $storageKey

  echo $diskName
  #TODO remove encrpytion
#  sudo cryptsetup luksFormat /dev/$diskName
#  #enter diskKey
#  sudo cryptsetup open /dev/$diskName safekey_drive
#  ls /dev/mapper
#
#  sudo mkfs.ext4 /dev/mapper/safekey_drive
#  sudo mount /dev/mapper/safekey_drive /mnt
#   sudo mkfs -t ext4 /dev/$diskName
#   lsblk -f
   #sudo mount /dev/$diskName /mnt

#  ls /mnt

  sudo cp $INSTALLER_DIR/safekey-login.c /opt/safelogin/

  safekey_path=/opt/safelogin/safekey-login.c
  ls -l $safekey_path

  keys_file=/opt/safelogin/keys.dat
  keys_file_encrypted=/opt/safelogin/keys.dat.gpg
  otp_file=/opt/safelogin/otp.dat

    sudo sed -i -e "s~{server_protocol}~${server_protocol}~g" $safekey_path
    sudo sed -i -e "s~{server_host}~${server_host}~g" $safekey_path
    sudo sed -i -e "s~{server_port}~${server_port}~g" $safekey_path
    sudo sed -i -e "s~{user}~${user}~g" $safekey_path
    sudo sed -i -e "s~{password}~${password}~g" $safekey_path
    sudo sed -i -e "s~{disk_name}~${diskName}~g" $safekey_path
    sudo sed -i -e "s~{keys_file}~${keys_file}~g" $safekey_path
    sudo sed -i -e "s~{keys_file_encrypted}~${keys_file_encrypted}~g" $safekey_path
    sudo sed -i -e "s~{otp_file}~${otp_file}~g" $safekey_path

  #if device uuid is empty, register new device and generate uuid
  if [ -z "$device_uuid" ]; then
    url=$server_protocol://$server_host:$server_port/safekey/device
    postDataJson='{ "deviceName" : "'$device_name'", "deviceDescription" : "'$device_description'" }'
    echo ${url} ${postDataJson}

    if [ $self_signed -eq 1 ]; then
      post_request=$(curl -k -u "$user:$password" -X POST "${url}" -H "Content-Type: application/json" -d "${postDataJson}")
    else
      post_request=$(curl -u "$user:$password" -X POST "${url}" -H "Content-Type: application/json" -d "${postDataJson}")
    fi
    device_uuid=$(echo "${post_request}" | jq '.uuid' | tr -d '"')
    if [ ! -z "$device_uuid" ]; then
      echo "UUID $device_uuid"
    fi
  fi
  url=$server_protocol://$server_host:$server_port/safekey/keys/download?uuid=$device_uuid
  echo $url

  if [ $self_signed -eq 1 ]; then
    get_request=$(sudo curl -k -u "$user:$password" -X GET "${url}" -o $keys_file)
  else
    get_request=$(sudo curl -u "$user:$password" -X GET "${url}" -o $keys_file)
  fi
  echo $get_request

  ls -l $keys_file
  if [ ! -f $keys_file ]; then
      echo "File not found!"
  fi

  filesize=$(stat -c%s "$keys_file")
  echo "Size of $keys_file = $filesize bytes."

  if (( filesize > 10000 )); then
    echo "File download successful"
  else
    echo "Something went wrong. Check $keys_file"
    exit 1
  fi

  #head -2 /mnt/keys.dat
    echo $(head -n 1 $keys_file) | sudo tee $otp_file
    sudo sed -i '1d' $keys_file

    #sudo gpg --full-generate-key
    #sudo gpg --list-secret-keys --keyid-format=long

    #sudo gpg -c --no-symkey-cache $keys_file
    #echo "Enter user: ${SET}"
    #echo "* This is the user you used when you first run gpg --full-generate-key as root"
    #read gpg_user

    #echo test | sudo gpg --batch --yes --passphrase-fd 0 --symmetric /opt/keys.dat
    echo $storageKey | sudo gpg --batch --yes --passphrase-fd 0 --symmetric $keys_file
    ls -l $keys_file_encrypted
    sudo rm $keys_file

    #sudo umount /mnt
    #sudo cryptsetup close safekey_drive
    sudo sed -i -e "s~{gpg_user}~${gpg_user}~g" $safekey_path

    cecho "Disk initialized!" $blue

    sudo sed -i -e "s~{device_uuid}~${device_uuid}~g" $safekey_path

    check_cjson=$(ls -l /usr/local/lib | grep libcjson)
    if [ -z "$check_cjson" ]; then
        cecho "Installing cJSON library.." $yellow
        unzip cJSON-1.7.18.zip
        cd cJSON-1.7.18
        mkdir build
        cd build/
        cmake ..
        sudo make install
        make
        sudo ldconfig /usr/local/lib
        cecho "cJSON installed.." $blue
    fi

    cecho "Compiling SafeKey.." $yellow
    sudo gcc $safekey_path -o /opt/safelogin/safekey -lcjson -lcurl -lcryptsetup
    sudo rm $safekey_path
    cecho "SafeKey compiled.." $blue

    cd $INSTALLER_DIR

    if [ $self_signed -eq 0 ]; then
      sed -i -e 's/-k//' login.sh
    fi
    sed -i -e "s~{device_uuid}~${device_uuid}~g" login.sh
    sed -i -e "s~{server_protocol}~${server_protocol}~g" login.sh
    sed -i -e "s~{server_host}~${server_host}~g" login.sh
    sed -i -e "s~{server_port}~${server_port}~g" login.sh
    sed -i -e "s~{apiuser}~${user}~g" login.sh
    sed -i -e "s~{apipassword}~${password}~g" login.sh
    sudo cp login.sh logout.sh /opt/safelogin/
    echo "date,ip_address,user_name,operation,status" | sudo tee /opt/safelogin/audit.csv

    cecho "SafeKey installed! Run manually /opt/safelogin/login.sh as root..." $blue
    #sudo /opt/safelogin/login.sh

}
main "$@"

