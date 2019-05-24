#!/usr/bin/env bash
# @author nightsparc
# @date 2019-05-24
# @brief Scale a desktop setup consisting of dual HP Z27 with GNOME
# @details
# The HP Z27 has a dpi of 163.
# 1) create a framebuffer with a scaled (1.25) width of 9600x2700
# 2) change the settings for the outputs. DP-2 -> left, DP-4 -> right
#   a) set mode / resolution
#   b) scale it. note: hidpi-scaling needs to be activated in X-Settings (see below)
#   c) pan the screens to their correct positions to enable correct access of the mouser
#
# @note
# GNOME HiDPi-Scaling:
# gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "[{'Gdk/WindowScalingFactor', <2>}]"
# gsettings set org.gnome.desktop.interface scaling-factor 2
# 
# @see
# - https://wiki.archlinux.org/index.php/HiDPI#GNOME
# - https://www.valhalla.fr/2018/07/14/hidpi-on-gnome-desktop/
# - https://blog.summercat.com/configuring-mixed-dpi-monitors-with-xrandr.html

xrandr --dpi 163 --fb 9600x2700 --output DP-2 --mode 3840x2160 --scale 1.25x1.25 --panning 4800x2700+0+0 --output DP-4 --mode 3840x2160 --scale 1.25x1.25 --panning 4800x2700+4800+0
