#!/bin/bash
# @date 2019-02-28
# @brief Short script to automatically change all commit names and email addresses to anonymize git repos
# @details
# Usage: ./git-author-rewrite.sh old-email new-name new-email
# @see Based on: https://help.github.com/articles/changing-author-info/

# @function Show the usage of the script
showUsage() {
    echo ""
    echo -e "Usage: $0 [OLD-EMAIL] [NEW-NAME] [NEW-EMAIL]"
    echo ""
    echo -e "Automatically change all commit names and email addresses to anonymize git repos."
    echo ""
    echo "OLD-EMAIL:  The email-address to be removed."
    echo "NEW-NAME:   The new name/ID for the commits after anonymization."
    echo "NEW-EMAIL:  The new email-address for the commits after anonymization."
}

# If not enough parameters are given, show help
if [ $# -le 2 ]; then
    echo "Not enough arguments given..."
	showUsage
	exit 1
fi

# defaults
# From: https://stackoverflow.com/a/46471405/1267320
OLD_EMAIL=${1:-"you_wrong_mail@hello.world"}
CORRECT_NAME=${2:-"your name"}
CORRECT_EMAIL=${3:-"new_mail@hello.world"}

echo "Old mail: $OLD_EMAIL"
echo "New name: $CORRECT_NAME"
echo "New mail: $CORRECT_EMAIL"
echo "Starting conversion in 1 sec..."
sleep 1

git filter-branch --env-filter "
if [ \$GIT_COMMITTER_EMAIL = '$OLD_EMAIL' ]
then
    export GIT_COMMITTER_NAME='$CORRECT_NAME'
    export GIT_COMMITTER_EMAIL='$CORRECT_EMAIL'
fi
if [ \$GIT_AUTHOR_EMAIL = '$OLD_EMAIL' ]
then
    export GIT_AUTHOR_NAME='$CORRECT_NAME'
    export GIT_AUTHOR_EMAIL='$CORRECT_EMAIL'
fi
" --tag-name-filter cat -- --branches --tags
