#!/bin/bash
#title          :expandfs.sh
#description    :This script is used to expand filesystem without the need to use raspi-config.
#author			:Bruno Fernandes {brunof@fe.up.pt, 1080557@isep.ipp.pt}
#date           :25-02-2016
#version        :1
#usage			:expandfs.sh
#notes          : This application searches for the partition where root filesystem is installed.
#==============================================================================

# Filenames Here
DEV_PATH="/dev/"						# Path were SD Cards are usually mounted on OS

##############################

# ROOT_PART=$(grep -Po '(?<=root=/dev/).*' /proc/cmdline | awk '{print $1}')		# ROOT_PART=$(readlink /dev/root)
ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
PART_NUM=${ROOT_PART#mmcblk0p}

if [ "$PART_NUM" = "$ROOT_PART" ]; then
	echo "/dev/root is not an SD card. Don't know how to expand"
	return 0
fi

LAST_PART_NUM=$(sudo parted /dev/mmcblk0 -ms unit s p | tail -n 1 | cut -f 1 -d:)
if [ "$LAST_PART_NUM" != "$PART_NUM" ]; then
	echo "/dev/root is not the last partition. Don't know how to expand"
	return 0
fi

# Get the starting offset of the root partition
# PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | cut -f 1 -d 's')
PART_START=$(sudo parted /dev/mmcblk0 -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
[ "$PART_START" ] || return 1

sudo fdisk /dev/mmcblk0 << EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF

# now set up an init.d script
sudo su -c cat << EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 2
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs $DEV_PATH$ROOT_PART &&
    update-rc.d resize2fs_once remove &&
    rm /etc/init.d/resize2fs_once &&
    log_end_msg \$?1
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF
sudo chmod +x /etc/init.d/resize2fs_once &&
sudo update-rc.d resize2fs_once defaults &&

echo ""
echo "Root partition has been resized."
echo "The filesystem will be enlarged upon the next reboot"
exit

# Creating the symlink allows File Exapanding from raspi-config possible, however when it reboots for some reason it does not update the partition table in kernel. Hence I have to type "resize2fs /dev/mmcblk0p2" after reboot. This is more a problem than a solution.


# sudo su
# cd /
# ln -s mmcblk0p2 /dev/root
# exit



# sudo su
# cd /
# sudo ln -snf mmcblk0p2 /dev/root
# exit


