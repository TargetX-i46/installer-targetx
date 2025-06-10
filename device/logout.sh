#!/bin/bash

token_file=/opt/safelogin/token.dat
cookies=cookies.txt
if [ -f $token_file ]; then
  sudo rm $token_file
  if [ -f $cookies ]; then
    sudo rm $cookies
  fi
  echo "You have logged out"
else
  echo "No sessions found"
fi