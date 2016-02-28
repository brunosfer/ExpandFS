#!/bin/bash
#title          :expandfs.sh
#description    :This script is used to expand filesystem without the need to use raspi-config.
#author			:Bruno Fernandes {brunof@fe.up.pt, 1080557@isep.ipp.pt}
#date           :28-02-2016
#version        :1
#usage			:expandfs.sh
#notes          : This application searches for the partition where root filesystem is installed.
#==============================================================================

# Device prefix
DEV_PATH="/dev/"

# Read the root partition
ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')       # Replacement for the "readlink /dev/root"
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

# This script is to update partition tables in kernel and it will run only once on boot "runtime 2" and after that it will remove itself.
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
exit $?