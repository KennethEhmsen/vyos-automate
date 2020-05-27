#!/usr/bin/env bash

disk=$1
password=$2
run="/opt/vyatta/bin/vyatta-op-cmd-wrapper"

# Check that the disk and password arguments is set
if [ $# -ne 2 ]; then
    echo "Usage: $0 <disk> <password>"
    exit 1
fi

# Download temp packages for autoinstall (1.2.x jessie)
wget http://ftp.de.debian.org/debian/pool/main/e/expect/expect_5.45-6_amd64.deb
wget http://ftp.de.debian.org/debian/pool/main/t/tcl8.6/libtcl8.6_8.6.2+dfsg-2_amd64.deb
wget http://ftp.de.debian.org/debian/pool/main/e/expect/tcl-expect_5.45-6_amd64.deb

dpkg -i *.deb

expect <<EOF

  spawn $run install image

  expect "Would you like to continue?"  {send "Yes\r"}
  expect "Partition (Auto/Parted/Skip)"  {send "Auto\r"}
  expect "Install the image on? *d*"  {send "$disk\r"}
  expect "Continue?"  {send "Yes\r"}
  expect "How big of a root partition should I create?" {send "\r"}
  expect "What would you like to name this image?" {send "\r"}
  expect "Which one should I copy to "  {send "/opt/vyatta/etc/config/config.boot\r"}
  expect "Enter password for user 'vyos':" {send "$password\r"}
  expect "Retype password for user 'vyos':"  {send "$password\r"}
  expect "Which drive should GRUB modify the boot partition on?" {send "$disk\r"}
  expect "vyos@vyos:~$" {send "\r"}

EOF
