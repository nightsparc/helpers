#!/bin/sh

##
## Import an existing git repository (A) into another (B)
##
## Reference: http://gbayer.com/development/moving-files-from-one-git-repository-to-another-preserving-history/
##

REPO_A="$1"
REPO_A_DIR=$2
REPO_B="$3"

# Prep Repo A
git clone $REPO_A repoA
cd repoA
git remote rm origin
mkdir $REPO_A_DIR
git mv * $REPO_A_DIR
git add .
git status # do a sanity check
git commit
cd ..

# Prep Repo B
git clone $REPO_B repoB
cd repoB
git remote add repoA_branch ../repoA
git pull repoA_branch master
git remote rm repoA_branch
