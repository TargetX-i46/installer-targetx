#!/bin/bash

#Target X SafeKey Server installer
INSTALLER_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
export INSTALLER_DIR

source $INSTALLER_DIR/scripts/cecho.sh
source $INSTALLER_DIR/config.txt
set -e

function main()
{
  echo
  echo "${BCYAN}${SLINE}Target X SafeKey Server Installer v$version${SET}"
  echo
  if [[ $USER == root ]]; then
     cecho "This script must not run as root" $red 1>&2
     exit 1
  fi

  cecho "Ensuring system is up to date.."  $yellow
  sudo apt-get update -y
  cecho "System is up to date." $blue

  cecho "Upgrading the system.." $yellow
  sudo apt-get upgrade -y
  cecho "System upgraded." $blue

  cecho "Installing required packages..." $yellow
  sudo apt install git -y
  sudo apt install zip -y
  sudo apt install jq -y
  sudo apt install postgresql -y
  sudo apt install default-jdk -y
  sudo apt-get install tomcat10 tomcat10-admin -y
  cecho "Required packages installed!" $blue


  #sudo -i -u postgres
  #psql
  #CREATE USER i46 WITH PASSWORD 'password';
  #CREATE DATABASE target_x OWNER i46;
  #sudo chown postgres:postgres targetx-2025.sql
  #sudo mv targetx-2025.sql /var/lib/postgresql/
  #psql --username=postgres target_x < targetx-2025.sql

  java -version
  sudo chown tomcat:tomcat target-x.war
  sudo mv target-x.war /var/lib/tomcat10/webapps/


  #https://bitbucket.org/dfrc/i46_installer

  #/etc/nginx/sites-available/default
#          location /safekey/ {
#                   proxy_set_header X-Forwarded-Host $host:$server_port;
#                   proxy_set_header X-Forwarded-Server $host;
#                   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#                   proxy_cookie_path /target-x/ /;
#                   proxy_pass http://localhost:8080/target-x/;
#          }
}
main "$@"