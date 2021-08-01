#!/bin/bash

# script: list-nvidia.sh
# author: Craig Sanders <cas@taz.net.au>
# license: Public Domain (this script is too trivial to be anything else)

# options:
# default/none    list the packages, one per line
# -v              verbose (dpkg -l) list the packages
# -h              hold the packages with apt-mark
# -u              unhold the packages with apt-mark

# build an array of currently-installed nvidia packages.
PKGS=( $(dpkg -l '*nvidia*' '*cuda*' '*vdpau*' 2>/dev/null |
           awk '/^[hi][^n]/ && ! /mesa/ {print $2}') )

case "$1" in
  "-v") dpkg -l "${PKGS[@]}" ;;
  "-h") apt-mark hold "${PKGS[@]}" ;;
  "-u") apt-mark unhold "${PKGS[@]}" ;;
  *) printf "%s\n" "${PKGS[@]}" ;;
esac