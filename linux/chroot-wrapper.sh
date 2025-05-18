#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# chroot-usb.sh
#
# Description:
#   This script mounts a Linux installation from a USB device and chroots into it.
#   Assumes EFI on partition 1, /boot on partition 2, and root (/) on partition 3.
#   It sets up /dev, /dev/pts, /proc, /sys, /run to enable a fully functional chroot.
#
#   By default, it automatically unmounts everything after you exit the chroot.
#   You can disable this with --no-cleanup or manually trigger unmounting with --cleanup.
#
# Usage:
#   sudo ./chroot-usb.sh -d /dev/sdX
#   sudo ./chroot-usb.sh --cleanup
# -----------------------------------------------------------------------------

MOUNTPOINT="/mnt"

show_help() {
    cat <<EOF
Usage: $0 -d <device> [--no-cleanup] [--cleanup]

Description:
  Mounts a Linux system from a USB device and chroots into it.
  Assumes:
    - EFI partition on <device>1
    - /boot on <device>2
    - root (/) on <device>3

  Automatically mounts necessary filesystems:
    - /dev, /dev/pts, /proc, /sys, /run
  Mounts are made private to prevent propagation to the host.

  Automatically unmounts everything when you exit the chroot (unless disabled).

Options:
  -d, --device       Block device to mount (e.g., /dev/sda)
  --no-cleanup       Disable auto-unmount after exiting chroot
  --cleanup          Only unmount previously mounted paths, no chroot
  --help             Show this help message and exit

Examples:
  $0 -d /dev/sda              Mount and chroot, then auto-cleanup on exit
  $0 -d /dev/sda --no-cleanup Mount and chroot, leave everything mounted
  $0 --cleanup                Just unmount everything (manual cleanup)
EOF
    exit 0
}

# Early help
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        show_help
    fi
done

# Require root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Parse args
DEVICE=""
CLEANUP=0
AUTO_CLEANUP=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP=1
            shift
            ;;
        --no-cleanup)
            AUTO_CLEANUP=0
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

do_cleanup() {
    echo "Unmounting..."
    umount -l $MOUNTPOINT/dev/pts || true
    umount -l $MOUNTPOINT/run     || true
    umount -l $MOUNTPOINT/dev     || true
    umount -l $MOUNTPOINT/proc    || true
    umount -l $MOUNTPOINT/sys     || true
    umount -l $MOUNTPOINT/boot/efi || true
    umount -l $MOUNTPOINT/boot    || true
    umount -l $MOUNTPOINT         || true
    echo "Cleanup done."
}

if [ $CLEANUP -eq 1 ]; then
    do_cleanup
    exit 0
fi

if [ -z "$DEVICE" ]; then
    echo "Error: No device specified."
    show_help
fi

PART_EFI="${DEVICE}1"
PART_BOOT="${DEVICE}2"
PART_ROOT="${DEVICE}3"

for part in "$PART_EFI" "$PART_BOOT" "$PART_ROOT"; do
    if [ ! -b "$part" ]; then
        echo "Error: Partition $part not found."
        exit 1
    fi
done

# Mount root and isolate
mount "$PART_ROOT" $MOUNTPOINT
mount --make-private $MOUNTPOINT

# Mount other partitions
mount "$PART_BOOT" $MOUNTPOINT/boot
mount "$PART_EFI" $MOUNTPOINT/boot/efi

# Virtual FS
mount --bind /dev $MOUNTPOINT/dev
mount --bind /dev/pts $MOUNTPOINT/dev/pts
mount --bind /proc $MOUNTPOINT/proc
mount --bind /sys $MOUNTPOINT/sys
mount --bind /run $MOUNTPOINT/run

# Enable auto-cleanup unless disabled
if [ "$AUTO_CLEANUP" -eq 1 ]; then
    trap do_cleanup EXIT
fi

# Enter chroot
chroot $MOUNTPOINT /bin/bash

