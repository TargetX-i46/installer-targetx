#!/bin/bash
# color-echo.sh: Display colored messages.

# Reset
no_color='\033[0m'       # Text Reset

# Regular Colors
black='\033[0;30m'        # Black
red='\033[0;31m'          # Red
green='\033[0;32m'        # Green
yellow='\033[0;33m'       # Yellow
blue='\033[0;34m'         # Blue
purple='\033[0;35m'       # Purple
cyan='\033[0;36m'         # Cyan
gray='\033[0;37m'         # Gray
white='\033[0;0m'           # White

# Bold
bblack='\033[1;30m'       # Black
bred='\033[1;31m'         # Red
bgreen='\033[1;32m'       # Green
byellow='\033[1;33m'      # Yellow
bblue='\033[1;34m'        # Blue
bpurple='\033[1;35m'      # Purple
bcyan='\033[1;36m'        # Cyan
bgray='\033[1;37m'        # Gray
bwhite='\033[1m'        # White

# Underline
ublack='\033[4;30m'       # Black
ured='\033[4;31m'         # Red
ugreen='\033[4;32m'       # Green
uyellow='\033[4;33m'      # Yellow
ublue='\033[4;34m'        # Blue
upurple='\033[4;35m'      # Purple
ucyan='\033[4;36m'        # Cyan
ugray='\033[4;37m'        # Gray
uwhite='\033[4;0m'        # White

# Background
on_black='\033[40m'       # Black
on_red='\033[41m'         # Red
on_green='\033[42m'       # Green
on_yellow='\033[43m'      # Yellow
on_blue='\033[44m'        # Blue
on_purple='\033[45m'      # Purple
on_cyan='\033[46m'        # Cyan
on_gray='\033[47m'        # Gray
on_white='\033[40m'       # White

# TPUT
BOLD=`tput bold`
SLINE=`tput smul`
ELINE=`tput rmul`

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BBLACK=`tput bold; tput setaf 0`
BRED=`tput bold; tput setaf 1`
BGREEN=`tput bold; tput setaf 2`
BYELLOW=`tput bold; tput setaf 3`
BBLUE=`tput bold; tput setaf 4`
BMAGENTA=`tput bold; tput setaf 5`
BCYAN=`tput bold; tput setaf 6`
BWHITE=`tput bold; tput setaf 7`

SET=`tput sgr0`

# Color-echo.
# Arg $1 = Text
# Arg $2 = Color

cecho ()
{
local default_msg="No message." # Doesn't have to be local

message=${1:-$default_msg}   # Default text
color=${2:-$white}           # Default color

  echo -e "$color"
  echo "$message"
  tput sgr0                  # Restore the original terminal settings.
  return
}

start_cecho ()
{
  echo
  echo "${BYELLOW}${1}${SET}"
}

end_cecho ()
{
  echo "${BBLUE}${1}${SET}"
  echo
}
