#!/bin/bash

# @date 2019-02-28
# @brief Short script to automatically extract a (sub-)directory with all its commits from a git repository.

# @function Show the usage of the script
showUsage() {
    echo ""
    echo -e "Usage: $0 [REPO-URL] [DIRECTORY] [BRANCH] [NEW-REPO-URL]"
    echo ""
    echo -e "Automatically extract a (sub-)directory with all its commits from a git repository."
    echo ""
    echo "REPO-URL:       The remote address of the source repository."
    echo "DIRECTORY-NAME: The name of the directory to be extracted."
    echo "BRANCH:         (OPTIONAL) The name of the branch to extract the subdirectory from."
    echo "NEW-REPO-URL:   (OPTIONAL) The remote address for the target repository. Should be the path to an empty git repository!"
}

# If not enough parameters are given, show help
if [ $# -le 1 ]; then
    echo "Not enough arguments given..."
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
                        # Anything unknown is recorded for later
                        -h* |  --help )
                            HELP=true
                            ;;
                        * )
                            REMAINS="$REMAINS \"$OPT\""
                            break
                            ;;
                esac
                # Check for multiple short options
                # NOTICE: be sure to update this pattern to match valid options
                NEXTOPT="${OPT#-[brcdiuh]}" # try removing single short opt
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

SOURCE_REPO=$1
SOURCE_DIR=${1##*/} # extracts the basedir name of the repository address
EXTRACT_DIR_NAME=$2
EXTRACT_DIR_NAME_CLEAN=$EXTRACT_DIR_NAME.clean
BRANCH=${3:-master} # defaults to master if $3 is either unset or empty string
TARGET_REPO=$4

# analyse parameter
if [[ $HELP == true ]] ; then
	showUsage
	exit 0

else
    echo "Cloning branch \"$BRANCH\" of $SOURCE_REPO to $SOURCE_DIR for extraction of directory \"$EXTRACT_DIR_NAME\""
    sleep 1
    git clone -b $BRANCH $SOURCE_REPO $SOURCE_DIR
    cd $SOURCE_DIR
    # Delete origin to avoid accidential remote operations
    git remote rm origin
    # http://gbayer.com/development/moving-files-from-one-git-repository-to-another-preserving-history/
    # https://kaffeeumeins.de/extract-folder-from-git-repository-with-history-and-shrink-repository
    # `--prune-empty` - remove empty commits
    # `--tag-name-filter cat` - aktualiser tags if any
    # `-- --all` - Use the current
    git filter-branch --prune-empty --subdirectory-filter $EXTRACT_DIR_NAME -- --all
    cd ..
    echo "Cloning stripped repository to Cleaning repository now."
    sleep 1
    git clone --single-branch --branch $BRANCH file://$PWD/$SOURCE_DIR $EXTRACT_DIR_NAME_CLEAN

    # (OPTIONAL) push cleaned repository to remote if remote was given
    if [ ! -z "$TARGET_REPO" ] ; then
        echo "Target remote address given: $TARGET_REPO. Adding as origin to \"EXTRACT_DIR_NAME_CLEAN\" and pushing repository to remote."
        sleep 1
        cd $EXTRACT_DIR_NAME_CLEAN
        git remote set-url origin $TARGET_REPO
        git push -u origin master
        git push --tags
    fi
fi