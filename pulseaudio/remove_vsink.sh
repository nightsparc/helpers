#!/bin/bash

# @author ***REMOVED*** Schmitt
# @date 2016-04-05
# @brief Script to automatically check the status of svn repos in the directory.
# @ref http://askubuntu.com/questions/60837/record-a-programs-output-with-pulseaudio

# unload vsink, output will be automatically redirected to std output
pactl unload-module $1
