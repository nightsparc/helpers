#!/bin/bash

# @author nightsparc
# @date 2016-04-05
# @brief Script to automatically check the status of svn repos in the directory.
# @ref http://askubuntu.com/questions/60837/record-a-programs-output-with-pulseaudio

# First version
#pactl load-module module-null-sink sink_name=spotify
#pactl move-sink-input $INDEX spotify
#parec -d spotify.monitor | oggenc -b 192 -o spotify.ogg --raw -

# 1st, get default output for linking
#pacmd list-sinks | grep -A1 "* index"
DEFAULT_OUTPUT=$(pacmd list-sinks | grep -A1 "* index" | grep -E "name:" | sed -e 's/name: //g' | sed -e 's/^[ \t]*//;s/[<]//;s/[>]//;s/[ \t]*$//')
echo $DEFAULT_OUTPUT

# 2nd, create virtual sink
VSINK_NAME=vsink_$1
echo $VSINK_NAME
pactl load-module module-combine-sink sink_name=$VSINK_NAME slaves=$DEFAULT_OUTPUT \
    sink_properties=device.description="VSINK_$VSINK_NAME"

# 3rd, find applications input ID
APP_INDEX=$(pacmd list-sink-inputs | grep -E "application.name = \"spotify\"|index:" | \
    grep -E "application.name = \"spotify\"" -B1 | grep -e "index:" | grep -e "[0-9]\+" -o)
echo $APP_INDEX

# 4th, move the applications output to the vsink
pactl move-sink-input $APP_INDEX $VSINK_NAME
