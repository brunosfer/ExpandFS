# ExpandFS - Expand Filesystem for RPi

This script is used to expand your root filesystem to the maximum capability of your storage device. It's based on the raspi-config option "Expand Filesystem" with some neat tweaks. This script is a specific function that makes part of a bigger project that I'm working on, however I hope I can help someone with the symlink problem, or just want to make the process of expanding autonomous.

## Installation
Execute this script inside the RPi:

    sudo ./expandfs.sh

## Motivation
Upon installing fresh Raspbian Jessie and upgrading it to the last kernel version (**4.1.18-v7+**) the option "**Expand Filesystem**" in raspi-config menu stoped working. Symlink to the device root was broken. After I've tried every trick in the book for replicating that symlink with no success, I decided to write this script.

Running raspi-config menu selecting all the options each time you install a fresh image on your Raspberry Pi is just not practical, so I decided to add this script that only needs to be executed once.

This script doesn't rely in the symlink for the device root and therefore it should work all the time.

If you find some bugs or anything that can be improved please feel free to comment or contribute.