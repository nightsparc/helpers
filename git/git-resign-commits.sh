#!/bin/bash
# @brief Short script to resign all commits in the repository for a given E-Mail address.

# @function Show the usage of the script
showUsage() {
    echo ""
    echo -e "Usage: $0 [EMAIL-TO-RESIGN]"
    echo ""
    echo -e "Resign all commits for a given E-Mail adress."
    echo ""
    echo "EMAIL-TO-RESIGN:  The E-Mail address of the commits to be resigned."
}

echo "Num args: $#"

# If not enough parameters are given, show help
if [ "$#" -lt "1" ]; then
    echo "Not enough arguments given..."
	showUsage
	exit 1
fi

# defaults
# From: https://stackoverflow.com/a/46471405/1267320
EMAIL2RESIGN=${1:-"you_wrong_mail@hello.world"}

echo "Resigning commits for $EMAIL2RESIGN with configured GPG signing key."
echo "Starting resigning in 1 sec..."
sleep 1

git filter-branch --commit-filter 'if [ "$GIT_COMMITTER_EMAIL" = '$EMAIL2RESIGN' ];
  then git commit-tree -S "$@";
  else git commit-tree "$@";
  fi' HEAD

exit 0
