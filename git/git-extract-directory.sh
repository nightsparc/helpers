#!/usr/bin/env bash
# @date 2020-02-28
# @brief Short script to automatically extract a (sub-)directory with all its commits from a git repository.

## Activate some bash features
# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

# Set magic variables for current file, directory, os, etc.
__dir="$(cd "$(dirname "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[${__b3bp_tmp_source_idx:-0}]}")"
__base="$(basename "${__file}" .sh)"
# shellcheck disable=SC2034,SC2015
__invocation="$(printf %q "${__file}")$( (($#)) && printf ' %q' "$@" || true)"

## @function Show the usage of the script
showUsage() {
    echo -e "\nUsage: $0 -s [REPO-URL] -d [DIRECTORY] -b [BRANCH] -t [NEW-REPO-URL]"
    echo -e "\nAutomatically extract a (sub-)directory with all its commits from a git repository."
    echo -e "\nARGUMENTS"
	echo -e "  -h, --help \t\t Display this help and exit"
    echo -e "  -s, --source \t\t The remote address of the source repository."
    echo -e "  -d, --directory \t The name of the directory to be extracted."
    echo -e "  -b, --branch \t\t (OPTIONAL) The name of the branch to extract the subdirectory from. Defaults to \"master\""
    echo -e "  -t, --target \t\t (OPTIONAL) The remote address for the target repository. Should be the path to an empty git repository! Stops after extraction if none given."
    echo -e "\nEXAMPLES"
    echo "1) Extract the folder \"git\" from the helpers repository: "
    echo -e "  $0 -s https://github.com/nightsparc/helpers -d git - "
    echo -e "\n2) Extract the folder \"git\" from the helpers repository and push it to git-helpers."
    echo -e "  $0 -s https://github.com/nightsparc/helpers -d git -t https://github.com/nightsparc/git-helpers"
    echo ""
}

## Command line parsing
# From: http://stackoverflow.com/a/24501190/1267320
# Code template for parsing command line parameters using only portable shell
# code, while handling both long and short params, handling '-f file' and
# '-f=file' style param data and also capturing non-parameters to be inserted
# back into the shell positional parameters.
while [ -n "${1:-}" ]; do
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
                        -h* | --help )
                            HELP=true
                            ;;
                        -s* | --source )
                            SOURCE_REPO=$2
                            ;;
                        -d* | --directory )
                            EXTRACT_DIR_NAME=$2
                            ;;
                        -b* | --branch )
                            BRANCH=$2
                            ;;
                        -t* | --target )
                            TARGET_REPO=$2
                            ;;
                        * )
                            REMAINS="${REMAINS:-} \"$OPT\""
                            break
                            ;;
                esac
                # Check for multiple short options
                # NOTICE: be sure to update this pattern to match valid options
                NEXTOPT="${OPT#-[bdhst]}" # try removing single short opt
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
eval set -- "${REMAINS:-}"

# Set some variables as shortcuts
SOURCE_REPO=${SOURCE_REPO:-}
SOURCE_DIR=${SOURCE_REPO##*/} # extracts the basedir name of the repository address
WORK_DIR=$SOURCE_DIR.tmp
SOURCE_DIR_ORIG=$SOURCE_DIR.orig
EXTRACT_DIR_NAME=${EXTRACT_DIR_NAME:-}
EXTRACT_DIR_NAME_CLEAN=$EXTRACT_DIR_NAME.clean
BRANCH=${BRANCH:-master} # defaults to master if BRANCH is either unset or empty string
HELP=${HELP:-}

# analyse parameter
if [[ $HELP == true ]] ; then
	showUsage
	exit 0

else

    if [ -z "$SOURCE_REPO" ] ; then
        echo "Missing source repo argument! See help with --help!"
        exit 1
    fi

    if [ -z "$EXTRACT_DIR_NAME" ] ; then
        echo "Missing directory argument! See help with --help!"
        exit 1
    fi

    if [[ ! -d $SOURCE_DIR_ORIG ]] ; then
        echo "Cloning branch \"$BRANCH\" of $SOURCE_REPO to $SOURCE_DIR_ORIG for extraction of directory \"$EXTRACT_DIR_NAME\""
        git clone -b "$BRANCH" "$SOURCE_REPO" "$SOURCE_DIR_ORIG"
    else

        if [[ -d $WORK_DIR ]]; then
            echo "Working directory from prior extracting exists. Deleting it to avoid conflicts..."
            rm -rf $WORK_DIR
        fi
        cd "$SOURCE_DIR_ORIG"
        echo "Resetting source directory $SOURCE_DIR_ORIG"
        git reset --hard
        cd ..
    fi
    echo "Copying source directory $SOURCE_DIR_ORIG to work dir $WORK_DIR"
    cp -r "$SOURCE_DIR_ORIG" "$WORK_DIR"
    cd "$WORK_DIR"
    # Delete origin to avoid accidental remote operations
    git remote rm origin
    # http://gbayer.com/development/moving-files-from-one-git-repository-to-another-preserving-history/
    # https://kaffeeumeins.de/extract-folder-from-git-repository-with-history-and-shrink-repository
    # `--prune-empty` - remove empty commits
    # `--tag-name-filter cat` - aktualiser tags if any
    # `-- --all` - Use the current
    git filter-branch --prune-empty --subdirectory-filter "$EXTRACT_DIR_NAME" -- --all
    cd ..
    echo "Cloning stripped repository to clean repository now."
    sleep 1
    git clone --single-branch --branch "$BRANCH" file://"$PWD"/"$WORK_DIR" "$EXTRACT_DIR_NAME_CLEAN"

    # (OPTIONAL) push cleaned repository to remote if remote was given
    if [ ! -z "$TARGET_REPO" ] ; then
        echo "Target remote address given: $TARGET_REPO. Adding as origin to \"$EXTRACT_DIR_NAME_CLEAN\" and pushing repository to remote."
        sleep 1
        cd "$EXTRACT_DIR_NAME_CLEAN"
        git remote set-url origin "$TARGET_REPO"
        git push -u origin master
        git push --tags
    fi
fi

exit 0