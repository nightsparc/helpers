#!/usr/bin/env python3

import os
import sys
import argparse

# ANSI escape codes for colored terminal output
GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"

def check_filenames(folder_path, threshold, recursive):
    file_list = []

    # Walk through directory (optionally recursively)
    for root, _, files in os.walk(folder_path):
        for filename in files:
            name, _ = os.path.splitext(filename)  # Remove extension
            length = len(name)
            rel_path = os.path.relpath(os.path.join(root, filename), folder_path)
            file_list.append((rel_path, length))
        if not recursive:
            break  # Don't descend into subdirs if not requested

    file_list.sort()  # Sort alphabetically for consistent output

    # Print header
    print(f"{'Filename':<70}Length")
    print("-" * 80)

    # Print each file with color-coded length info
    for path, length in file_list:
        color = GREEN if length <= threshold else RED
        print(f"{color}{path:<70}{length}{RESET}")

def main():
    # Set up command-line argument parsing
    parser = argparse.ArgumentParser(
        description="Check filenames in a folder and mark those exceeding a given length (default: 30 characters, excluding extension)."
    )
    parser.add_argument(
        "-d", "--directory",
        required=True,
        help="Path to the folder to scan"
    )
    parser.add_argument(
        "-t", "--threshold",
        type=int,
        default=30,
        help="Threshold for filename length (default: 30)"
    )
    parser.add_argument(
        "-r", "--recursive",
        action="store_true",
        help="Recursively check subdirectories"
    )

    args = parser.parse_args()

    # Validate directory
    if not os.path.isdir(args.directory):
        print(f"Error: '{args.directory}' is not a valid directory.")
        sys.exit(1)

    check_filenames(args.directory, args.threshold, args.recursive)

if __name__ == "__main__":
    main()

