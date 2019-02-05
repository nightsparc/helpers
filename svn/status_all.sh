#!/bin/bash

# @author ***REMOVED*** Schmitt
# @date 2015-06-20
# @brief Script to automatically check the status of svn repos in the directory.

# resource the users bash_aliases if existing
BASH_ALIAS=${HOME}/.bash_aliases
if [ -f "$BASH_ALIAS" ] 
then
	shopt -s expand_aliases # enable aliases
	source $BASH_ALIAS
fi

# Loop through all files in $PWD
for f in *; 
do
	if [[ -d $f ]]; 
	then
		cd $f ;
		if [[ -d .svn  ]]
		then
			# $f is a directory
			echo "Checking svn status for $f..." ;
			svn status --ignore-externals ;
		fi
		cd .. ;
	fi
done
