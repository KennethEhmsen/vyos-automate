#!/usr/bin/env bash

disk=$1
password=$2
run="/opt/vyatta/bin/vyatta-op-cmd-wrapper"

# Check that the disk and password arguments is set
if [ $# -ne 2 ]; then
    echo "Usage: $0 <disk> <password>"
    # Show all disks in the system
    lsblk | grep disk | awk '{print $1}'
    exit 1
fi

# Download temp packages for autoinstall (1.3.x Buster)
curl --url http://ftp.de.debian.org/debian/pool/main/e/expect/expect_5.45.4-2_amd64.deb --output /tmp/expect.deb
curl --url http://ftp.de.debian.org/debian/pool/main/t/tcl8.6/libtcl8.6_8.6.9+dfsg-2_amd64.deb --output /tmp/libtcl8.deb
curl --url http://ftp.de.debian.org/debian/pool/main/t/tcl8.6/tcl8.6_8.6.9+dfsg-2_amd64.deb --output /tmp/tcl8.deb
curl --url http://ftp.de.debian.org/debian/pool/main/e/expect/tcl-expect_5.45.4-2_amd64.deb --output /tmp/tcl-expect.deb

# Install temp packagers
#sudo dpkg -i /tmp/libtcl8.deb /tmp/tcl-expect.deb /tmp/expect.deb
sudo dpkg -i /tmp/*.deb

preinstall() {

source /opt/vyatta/etc/functions/script-template
cfg="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"

$cfg begin
$cfg set system login user vyos authentication plaintext-password ${password}
$cfg set service ssh disable-host-validation
$cfg commit
$cfg save
$cfg end

}

# Install VyOS with only one disk (detected) in the system.
install_one_disk() {
 expect <<EOF

    spawn $run install image

    expect "Would you like to continue?"  {send "Yes\r"}
    expect "Partition (Auto/Parted/Skip)"  {send "Auto\r"}
    expect "Install the image on? *d*"  {send "$disk\r"}
    expect "Continue?"  {send "Yes\r"}
    expect "How big of a root partition should I create?" {send "\r"}
    sleep 20
    expect "What would you like to name this image?" {send "\r"}
    expect "Which one should I copy to "  {send "/opt/vyatta/etc/config/config.boot\r"}
    expect "Enter password for user 'vyos':" {send "$password\r"}
    expect "Retype password for user 'vyos':"  {send "$password\r"}
    expect "Which drive should GRUB modify the boot partition on?" {send "$disk\r"}
    expect "vyos@vyos:~$" {send "\r"}

EOF
}

# Install VyOS on system which detect more then one disk. Without RAID.
install_couple_disk() {
 expect <<EOF

    spawn $run install image

    expect "Would you like to continue?"  {send "Yes\r"}
    expect "Would you like to configure RAID"  {send "No\r"}
    expect "Partition (Auto/Parted/Skip)"  {send "Auto\r"}
    expect "Install the image on? *d*"  {send "$disk\r"}
    expect "Continue?"  {send "Yes\r"}
    expect "How big of a root partition should I create?" {send "\r"}
    sleep 20
    expect "What would you like to name this image?" {send "\r"}
    expect "Which one should I copy to "  {send "/opt/vyatta/etc/config/config.boot\r"}
    expect "Enter password for user 'vyos':" {send "$password\r"}
    expect "Retype password for user 'vyos':"  {send "$password\r"}
    expect "Which drive should GRUB modify the boot partition on?" {send "$disk\r"}
    expect "vyos@vyos:~$" {send "\r"}

EOF
}

# How many disks. Different interactive installers for one and more disks
if [ `lsblk | grep disk | awk '{print $1}' | wc -l` -eq 1 ]; then
    echo "1 disk"
    preinstall
    install_one_disk
else
    echo "2 or more disks"
    preinstall
    install_couple_disk
fi

