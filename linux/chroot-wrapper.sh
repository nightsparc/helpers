#!/bin/bash
set -e

MOUNTPOINT="/mnt"

show_help() {
    echo "Usage: $0 -d <device> [--cleanup]"
    echo
    echo "Options:"
    echo "  -d, --device   Target device (e.g., /dev/sda)"
    echo "      --cleanup  Unmount all mounted paths under /mnt"
    echo "      --help     Show this help message"
    exit 0
}

# Early --help handling
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        show_help
    fi
done

# Require root for actions other than --help
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Parse arguments
DEVICE=""
CLEANUP=0

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
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

if [ $CLEANUP -eq 1 ]; then
    echo "Unmounting..."
    umount -l $MOUNTPOINT/run || true
    umount -l $MOUNTPOINT/dev || true
    umount -l $MOUNTPOINT/proc || true
    umount -l $MOUNTPOINT/sys || true
    umount -l $MOUNTPOINT/boot/efi || true
    umount -l $MOUNTPOINT/boot || true
    umount -l $MOUNTPOINT || true
    echo "Cleanup done."
    exit 0
fi

if [ -z "$DEVICE" ]; then
    echo "Error: No device specified."
    show_help
fi

PART_EFI="${DEVICE}1"
PART_BOOT="${DEVICE}2"
PART_ROOT="${DEVICE}3"

# Check required partitions
for part in "$PART_EFI" "$PART_BOOT" "$PART_ROOT"; do
    if [ ! -b "$part" ]; then
        echo "Error: Partition $part not found."
        exit 1
    fi
done

# Mount root and submounts
mount "$PART_ROOT" $MOUNTPOINT
mount "$PART_BOOT" $MOUNTPOINT/boot
mount "$PART_EFI" $MOUNTPOINT/boot/efi

mount --bind /dev $MOUNTPOINT/dev
mount --bind /proc $MOUNTPOINT/proc
mount --bind /sys $MOUNTPOINT/sys
mount --bind /run $MOUNTPOINT/run

# Chroot
chroot $MOUNTPOINT /bin/bash

