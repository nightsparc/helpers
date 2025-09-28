#!/bin/bash
# Add .gitkeep files to empty subfolders of a Git working copy

# Ensure we're in a Git working copy
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Not inside a Git working copy. Aborting."
    exit 1
fi

find . -type d ! -path '*/.git/*' | while read -r dir; do
    # skip if dir has contents (anything except .gitkeep)
    if [ "$(find "$dir" -mindepth 1 -not -name '.gitkeep' | head -n1)" ]; then
        continue
    fi

    file="$dir/.gitkeep"
    if [ ! -f "$file" ]; then
        {
            echo "# This .gitkeep ensures the directory is tracked by Git even if empty."
            echo "# Remove it if the directory contains real content."
        } > "$file"
        git add "$file"
        echo "Added .gitkeep to $dir"
    fi
done

