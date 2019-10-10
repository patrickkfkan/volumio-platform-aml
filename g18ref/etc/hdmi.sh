#!/bin/sh
################################################################################
#      This file is part of LibreELEC - https://libreelec.tv
#      Copyright (C) 2014 Alex Deryskyba (alex@codesnake.com)
#
#  LibreELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  LibreELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with LibreELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

hdmimode="720p"

# Parse command line arguments
for arg in $(cat /proc/cmdline); do
  case $arg in
    hdmimode=*)
      hdmimode="${arg#*=}"
      ;;
  esac
done

echo "$hdmimode" > /sys/class/display/mode

# Enable first framebuffer
echo 0 > /sys/class/graphics/fb0/blank

# Disable second framebuffer
echo 1 > /sys/class/graphics/fb1/blank

# Disable framebuffer scaling
echo 0 > /sys/class/graphics/fb0/free_scale

# set initial video state
echo 1 > /sys/class/video/disable_video

# Set default resolution parameters
bpp=32;
xRes=1280;
yRes=720;

# Get max supported display resolution by hdmi device
maxRes=$(tail -n1 /sys/class/amhdmitx/amhdmitx0/disp_cap | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//');
if [ -z "$maxRes" ]; then
  maxRes="$hdmimode";
fi
case "$maxRes" in
  480*)
    xRes=720; yRes=480;
    ;;
  576*)
    xRes=720; yRes=576;
    ;;
  1080*)
    xRes=1920; yRes=1080;
    ;;
  4k2k*hz|2160p*)
    xRes=3840; yRes=2160;
    ;;
  4k2ksmpte|smpte24hz)
    xRes=4096; yRes=2160;
    ;;
esac
vXRes=$xRes;
vYRes=$(( $yRes * 2 ));

# Choose boot resolution by hdmimode param
case "$hdmimode" in
  480*)
    if [ "$vXRes" -ge 720 -a "$vYRes" -ge 960 ]; then
      xRes=720; yRes=480;
    fi
    ;;
  576*)
    if [ "$vXRes" -ge 720 -a "$vYRes" -ge 1152 ]; then
      xRes=720; yRes=576;
    fi
    ;;
  720*)
    if [ "$vXRes" -ge 1280 -a "$vYRes" -ge 1440 ]; then
      xRes=1280; yRes=720;
    fi
    ;;
  1080*)
    if [ "$vXRes" -ge 1920 -a "$vYRes" -ge 2160 ]; then
      xRes=1920; yRes=1080;
    fi
    ;;
  4k2k*hz|2160p*)
    if [ "$vXRes" -ge 3840 -a "$vYRes" -ge 4320 ]; then
      xRes=3840; yRes=2160;
    fi
    ;;
esac

# Set framebuffer geometry to match the resolution
fbset -fb /dev/fb0 -g $xRes $yRes $vXRes $vYRes $bpp;

# Include deinterlacer into default VFM map
echo rm default > /sys/class/vfm/map
echo add default decoder ppmgr deinterlace amvideo > /sys/class/vfm/map
