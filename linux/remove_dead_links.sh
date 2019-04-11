#!/bin/bash

# @author nightpsarc
# @date 2016-12-05
# @brief Script to automatically clean dead symlinks in a given directory.
# @details
# The script automatically cleans dead symlinks in a given directory.
# @url https://wiki.ifs.lrt.unibw-muenchen.de/doku.php?id=software:tips_tricks:linux:brokensymlink

# @function Show the usage of the script
showUsage() {
    echo ""
    echo -e "Usage: $0 [OPTIONS] [DIRECTORY] [MODIFIERS]"
    echo ""
	echo -e "Automatically clean dead symlinks in a given directory."
    echo ""
    echo "OPTIONS"
    echo -e "  -h, --help  \t\t Display this help and exit."
    echo -e "  -d, --display \t\t Shows dead links in the directory and returns. (exclusive)"
    echo -e "  -r, --remove \t\t Remove dead links with confirmation. (exclusive)"
    echo ""
    echo "MODIFIERS"
    echo -e "  -s, --superuser \t\t Execute as superuser." 
    echo "" 
    echo "EXAMPLES"
    echo -e "  $0 --display /usr/local/lib \t Show dead links in /usr/local/lib and returns."
    echo -e "  $0 -r /usr/local/lib \t\t Shows and removes dead links in /usr/local/lib after confirmation."
    echo -e "  $0 -r /usr/local/lib --immediately -s \t Shows and removes dead links in /usr/local/lib WITHOUT confirmation as superuser."
    echo ""
    echo "ATTENTION:"
    echo "Be careful when using the --immediately option!!"
    
}

# @function Echo to stderr
echoerr() { 
    echo -e "\e[31mERROR: $@ \e[0m" 1>&2; 
}

#############################################################################
#### START of script execution

# Print naked parameters 
#echo "Arguments: "
#for i ; do echo " $i" ; done

# If not enough parameters are given, show help too
if [ $# == 0 ]; then
    echoerr "No arguments given..."
	showUsage
	exit 1
fi

# From: http://stackoverflow.com/a/24501190/1267320
# Code template for parsing command line parameters using only portable shell
# code, while handling both long and short params, handling '-f file' and
# '-f=file' style param data and also capturing non-parameters to be inserted
# back into the shell positional parameters.
while [ -n "$1" ]; do
        # Copy so we can modify it (can't modify $1)
        OPT="$1"
        # Detect argument termination
        if [ x"$OPT" = x"--" ]; then
                shift
                for OPT ; do
                    REMAINS="$REMAINS \"$OPT\""
                done
                break
        fi
        
        # Parse current opt / argument
        while [ x"$OPT" != x"-" ] ; do
                case "$OPT" in
                        # Handle --flag=value opts like this
                        #-c=* | --config=* )
                            #CONFIGFILE="${OPT#*=}"
                            #shift
                            #;;
                        # and --flag value opts like this
                        -d* | --display )
                            ONLY_DISPLAY=true
                            FOLDER="$2"
                            shift
                            ;;
                        -r* | --remove )
                            REMOVE=true
                            FOLDER="$2"
                            shift
                            ;;
                        -s* | --superuser )
                            SUPERUSER="sudo"
                            ;;
                        -h* |  --help )
                            HELP=true
                            ;;
                        # Anything unknown is recorded for later
                        * )
                            REMAINS="$REMAINS \"$OPT\""
                            break
                            ;;
                esac
                # Check for multiple short options
                # NOTICE: be sure to update this pattern to match valid options
                NEXTOPT="${OPT#-[brcdiujhs]}" # try removing single short opt
                if [ x"$OPT" != x"$NEXTOPT" ] ; then
                        OPT="-$NEXTOPT"  # multiple short opts, keep going
                else
                        break  # long form, exit inner loop
                fi
        done
        # Done with that param. move to next
        shift
done
# Set the non-parameters back into the positional parameters ($1 $2 ..)
eval set -- $REMAINS

#echo -e "After parsing: \n folder='$FOLDER' \n remove='$REMOVE \n display='$ONLY_DISPLAY' \n superuser=$SUPERUSER"

# analyse parameter
if [[ $HELP == true ]]; then
	showUsage
         
else
    if [[ ! -d $FOLDER ]]; then
        echoerr "Given folder $FOLDER is invalid!"
        showUsage
        exit 1
    fi

    if [[ $ONLY_DISPLAY == true && $REMOVE == true ]]; then
        echoerr "Invalid argument combination! Use --remove or --display exclusively!!"
        showUsage
        exit 1
    fi
    
    echo "Found dead symbolic links in $FOLDER:"
    $SUPERUSER find -L $FOLDER -type l
    
    if [[ $REMOVE == true ]]; then
        read -p "Ok to delete them? (y/n)" ans ;
        case $ans in
            [yY]*) $SUPERUSER find -L $FOLDER -type l -delete ;;
            
            *) echo "...Nothing deleted! Dead links in $FOLDER are still existing!";;
        esac
    fi    
fi

exit 0
