#!/bin/bash

# @author nightsparc
# @date 2015-06-20
# @brief Scripit to automatically update all svn repos in the directory.

# Loop through all files in $PWD
for f in *;
do
	if [[ -d $f ]];
	then
		cd $f ;
		if [[ -d .svn  ]]
		then
			# $f is a directory
			echo "Relocating $f..." ;
			svn relocate https://code.ifs.lrt.unibw-muenchen.de/svn/repos/$f ;
		fi
		cd .. ;
	fi
done
