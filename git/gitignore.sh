#!/bin/bash
# To add two items to the current .gitignore file:
# gitignore '*.swp' bin
#
# To sort and de-dupe the current .gitignore file:
# gitignore
#
# Copied from: https://gist.github.com/judy2k/9930888

# Append each argument to its own line:
for item in "$@"; do
    echo "$item" >> .gitignore;
done

# Remove duplicates (and sort):
sort -u .gitignore -o .gitignore
