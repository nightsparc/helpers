#!/bin/bash

# @author nightsparc
# @date 2016-06-05
# @brief Script to automatically create symlinks to /usr/local/lib for 
#        'lib' subdirs.
# @details
# Somehow, ubuntu forgets some symlinks in /usr/local/lib. DKY...

# resource the users bash_aliases if existing
BASH_ALIAS=${HOME}/.bash_aliases
if [ -f "$BASH_ALIAS" ] 
then
	shopt -s expand_aliases # enable aliases
	source $BASH_ALIAS
fi

LINK_DIR=/usr/local/lib

# Loop through all files in $PWD
for f in *; 
do
	if [[ -d $f ]]; 
	then
		# $f is a directory
		cd $f ;
		if [[ -d lib  ]]
		then
		    cd lib ;
		    # lib exists
			echo "Linking .so files in $f/lib to $LINK_DIR..." ;
			# Create symlinks for shared libraries
			for sofile in $PWD/*.so* ;
			do
				#echo "Linking $sofile to $LINK_DIR/$(basename $sofile)"
				sudo ln -fns $sofile $LINK_DIR/$(basename $sofile)
			done
			
			echo "Linking .a files in $f/lib to $LINK_DIR..." ;
			# Create symlinks for shared libraries
			for archfile in $PWD/*.a* ;
			do
				#echo "Linking $archfile to $LINK_DIR/$(basename $archfile)"
				sudo ln -fns $archfile $LINK_DIR/$(basename $archfile)
			done
			cd ..
		fi
		cd ..
	fi
done

echo "Refreshing ldconfig linker cache..."
sudo ldconfig
