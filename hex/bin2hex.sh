#!/bin/sh
# From: https://unix.stackexchange.com/a/352570/161032

hexdump -v -e '1/1 "%02x"' "$1"
