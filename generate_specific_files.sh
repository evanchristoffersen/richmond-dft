#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# gnu sed (gsed)

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

re="^[1-9][0-9]*$" # sets up regular expression for only positive integers not including 0

# sorts all normalized results in order of increasing conformer energy
sort -k2 -n -t, ./tmpfiles/tmp/gaff_tmp.csv >> ./tmpfiles/gaff_results.csv
sort -k2 -n -t, ./tmpfiles/tmp/mmff94_tmp.csv >> ./tmpfiles/mmff94_results.csv
sort -k2 -n -t, ./tmpfiles/tmp/uff_tmp.csv >> ./tmpfiles/uff_results.csv

echo
echo Enter the index number for the conformer at which you would like to start.
echo Starting index:
read first
echo

while ! [[ ${first} =~ ${re} ]]; do 
	echo ERROR: Please enter an integer value of 1 or greater.
	echo Try again or press CTRL+C to exit:
	read first 
	echo
done

echo Enter the index number for the conformer at which you would like to end.
echo Ending index:
read last
echo

while ! [[ ${last} =~ ${re} ]]; do 
	echo
	echo ERROR: Please enter an integer value of 1 or greater.
	echo Try again or press CTRL+C to exit:
	read last 
	echo
done

while IFS="," read conformer energy; do
	echo "$conformer" >> ./tmpfiles/tmp/gtmp.csv
done < ./tmpfiles/gaff_results.csv &
while IFS="," read conformer energy; do
	echo "$conformer" >> ./tmpfiles/tmp/mtmp.csv
done < ./tmpfiles/mmff94_results.csv &
while IFS="," read conformer energy; do
	echo "$conformer" >> ./tmpfiles/tmp/utmp.csv
done < ./tmpfiles/uff_results.csv &
wait

gsed -n "${first},${last} p" ./tmpfiles/tmp/gtmp.csv >> ./tmpfiles/tmp/g2tmp.csv
gsed -n "${first},${last} p" ./tmpfiles/tmp/mtmp.csv >> ./tmpfiles/tmp/m2tmp.csv
gsed -n "${first},${last} p" ./tmpfiles/tmp/utmp.csv >> ./tmpfiles/tmp/u2tmp.csv

for file in ./tmpfiles/tmp/*2tmp.csv; do
	cat "$file" >> ./tmpfiles/tmp/tmp.csv
done

sort ./tmpfiles/tmp/tmp.csv > ./tmpfiles/tmp/tmp2.csv
uniq ./tmpfiles/tmp/tmp2.csv ./tmpfiles/reduced_conf_library_${first}_${last}.csv

echo Cleaning up...
rm -r ./tmpfiles/tmp/
echo Done.
echo
