#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# find
# grep

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

echo
echo Scanning files for failed Gaussian termination...

# Searches current and all subdirectories for any file with the .out extension
# If the string "Normal termination of Gaussian" is not found in the .out file
# then the file name is printed to the terminal
for file in $( find . \( ! -regex '.*/\..*' \) -type f -name "*.out" ); do
# the regex bit allows the find command to ignore hidden files and folders
if ! grep -q "Normal termination of Gaussian" "${file}"; then
		echo "${file}" did not terminate correctly
	else
		:
	fi
done

echo
echo Done.
echo

