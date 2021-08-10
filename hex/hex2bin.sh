#!/bin/sh
# From: https://unix.stackexchange.com/a/352570/161032
sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' "$1" | xargs printf
