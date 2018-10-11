#!/bin/sh
#
# Perform necessary steps to uninstall
# Chef Workstation.
#

PROGNAME=`basename $0`

error_exit()
{
  echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
  exit 1
}

is_darwin()
{
  uname -v | grep "^Darwin" 2>&1 >/dev/null
}

if is_darwin; then
  echo "This uninstaller will remove Chef Workstation"
  if ! sudo -n true 2>/dev/null; then 
    echo "Enter your password to continue"
  fi
  echo "Closing Chef Workstation App"
  osascript -e 'quit app "Chef Workstation App"'
  sudo -s -- <<EOF
echo "Uninstalling Chef Workstation"
echo "Removing files"
sudo rm -rf '/opt/chef-workstation'
sudo rm -rf '/Applications/Chef Workstation App.app'
echo "Removing binary links in /usr/local/bin"
sudo find /usr/local/bin -lname '/opt/chef-workstation/*' -delete
echo "Forgeting com.getchef.pkg.chef-workstation package"
sudo pkgutil --forget com.getchef.pkg.chef-workstation
echo "Chef Workstation Uninstalled"
EOF
fi