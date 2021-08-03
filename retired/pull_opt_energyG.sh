#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# compgen
# gnu sed (gsed)
# grep

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

# Instead of exiting script on existing csv file containing sorted energies and
# conformer names for the electronic structure calculation results, this if..fi
# loop appends a number to a new file so you can keep old results and new ones
# without being kicked out of the program or manually having to rename them
i=2 # initialize i
# if [ -e ./conformer_energies*.csv ]; then # this fails if more than one
# instance of the globbed file exists - used non POSIX compliant compgen instead 
if compgen -G "./tmpfiles/conformer_energies*csv" &>/dev/null; then
    while [ -e "./tmpfiles/conformer_energies_${i}.csv" ]; do
        i=$((i+1)) # "let i++" throws a nonzero exit status
    done
    filename="conformer_energies_${i}.csv"
else
    filename="conformer_energies.csv"
fi

echo
echo Checking opt.out files for normal Gaussian termination... 

for f in ./conformer_files/conf*/*_opt.out; do
	a="${f%_opt*}"
	a="${a##*/}"
	if ! grep -q "Normal termination of Gaussian 09 at" "${f}"; then
		echo WARNING: "${f##*/}" did not terminate normally!
		echo "${a}","IMPROPER_TERMINATION" >> "./tmpfiles/tmp.csv"
	else
		b=$(gsed -n "/GINC/,/\@/p" ${f})
		b=$(echo ${b//[$'\t\r\n ']})
		b=${b#*HF=}
		b=${b%\\RMSD*}
		echo "${a}","${b}" >> "./tmpfiles/tmp.csv"
	fi
done
echo Done.
echo

echo Writing conformer names and energies to "./tmpfiles/${filename}"
sort -k2 -n -t, "./tmpfiles/tmp.csv" > "./tmpfiles/${filename}"
echo Done.
echo

