#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# gnu sed (gsed)
# grep

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

echo
echo Enter gaussian.out filename:
read -e f
echo

# Exits script if file doesn't exist
if [ ! -f ${f} ]; then
	echo "${f}" does not exist.
	echo Exiting script.
	echo
	exit
fi

# Exits script if Gaussian didn't terminate normally
if ! grep -q "Normal termination of Gaussian 09 at" "${f}"; then
	echo WARNING: "${f##*/}" did not terminate normally!
	echo Exiting script.
	echo
	exit
else
	a=$(gsed -n "/GINC/,/\@/p" ${f})
	a=$(echo ${a//[$'\t\r\n ']})
	a=${a#*HF=}
	a=${a%\\RMSD*}
	echo The energy of your optimized structure is: "${a}" Hartrees
	echo
fi

