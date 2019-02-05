#!/bin/bash

# @author ***REMOVED*** Schmitt
# @date 2015-06-20
# @brief Scripit to automatically update all svn repos in the directory.

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
        dir=${dir%*/} ;
        echo ${dir##*/} ;
		cd $f ;
		if [[ -d .svn  ]]
		then
			# $f is a directory
			echo "Updating $f..." ;
			svn update ;
		fi
		cd .. ;
	fi
done
