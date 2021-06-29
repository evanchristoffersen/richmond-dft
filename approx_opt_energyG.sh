#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# gnu sed (gsed)

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

start=$(date +%s)

if [ ! -d ./tmpfiles/ ]; then
	mkdir ./tmpfiles/
fi

mkdir ./tmpfiles/tmp/

re="^[1-9][0-9]*$" # sets up regular expression for only positive integers not including 0

if [[ ! -f ./tmpfiles/gaff_results.csv && ! -f ./tmpfiles/mmff94_results.csv && ! -f ./tmpfiles/uff_results.csv ]]; then
	if [[ ! -d ./geometries/ || ! -d ./geometries/unoptimized/ ]]; then
		echo No geometries detected from which to predict conformer energies in ./geometries/unoptimized/
		echo Exiting script.
		echo
		exit
	fi

	echo
	echo Note: This may take a while to run depending on the number of conformers you are working with.
	echo For fastest results, let the computer work and go find something else to do until finished.
	echo 300 conformers = ~1 min run time
	echo 3000 conformers = ~20 min run time
	echo
	
	echo Searching the geometries/unoptimized/ directory for unoptimized \*.xyz files and approximating their energies...
	echo
	# >/dev/null makes output not appear
	# 2>/dev/null makes error output not appear
	# uses the gaff, mmff94, and uff force fields to approximate the energies of each conformer and writes results to csv files
	# the "done & wait" text runs the three for loops in parallel descreasing the time it takes to approximate the conformer energies
	for f in ./geometries/unoptimized/*.xyz; do
		approxenergy="$(obenergy -h -ff GAFF "${f}" 2>/dev/null | grep "TOTAL ENERGY")"
		approxenergy="${approxenergy% *}"
		approxenergy="${approxenergy##* }"
		f="${f%.*}"
		f="${f##*/}"
		echo "${f}","${approxenergy}" >> ./tmpfiles/tmp/gaff_tmp.csv
	done & for f in ./geometries/unoptimized/*.xyz; do
		approxenergy2="$(obenergy -h -ff MMFF94 "${f}" 2>/dev/null | grep "TOTAL ENERGY")"
		approxenergy2="${approxenergy2% *}"
		approxenergy2="${approxenergy2##* }"
		f="${f%.*}"
		f="${f##*/}"
		echo "${f}","${approxenergy2}" >> ./tmpfiles/tmp/mmff94_tmp.csv
	done & for f in ./geometries/unoptimized/*.xyz; do
		approxenergy3="$(obenergy -h -ff UFF "${f}" 2>/dev/null | grep "TOTAL ENERGY")"
		approxenergy3="${approxenergy3% *}"
		approxenergy3="${approxenergy3##* }"
		f="${f%.*}"
		f="${f##*/}"
		echo Analyzing conformer "${f}"...
		echo "${f}","${approxenergy3}" >> ./tmpfiles/tmp/uff_tmp.csv
	done & wait
	
	echo Done.
	
	# sorts all normalized results in order of increasing conformer energy
	sort -k2 -n -t, ./tmpfiles/tmp/gaff_tmp.csv >> ./tmpfiles/gaff_results.csv
	sort -k2 -n -t, ./tmpfiles/tmp/mmff94_tmp.csv >> ./tmpfiles/mmff94_results.csv
	sort -k2 -n -t, ./tmpfiles/tmp/uff_tmp.csv >> ./tmpfiles/uff_results.csv

	end=$(date +%s)

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
#	rm -r ./tmpfiles/tmp/
	echo Done.
	echo

	duration=$(echo "$end - $start" | bc)
	echo Total run time: "$duration" seconds
	echo

elif [[ -f ./tmpfiles/gaff_results.csv && -f ./tmpfiles/mmff94_results.csv && -f ./tmpfiles/uff_results.csv ]]; then
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
#	rm -r ./tmpfiles/tmp/
	echo Done.
	echo
else
#	rm -r ./tmpfiles/tmp/
	echo
	echo Warning: you are missing one or two of the following files:
	echo ./tmpfiles/gaff_results.csv
	echo ./tmpfiles/mmff94_results.csv
	echo ./tmpfiles/uff_results.csv
	echo
	echo Conformer energy predictions are less likely to be accurate with missing forcefield approximations.
	echo Replace missing file, or delete the non-missing ones and re-run this script to generate fresh approximations.
	echo Exiting script.
	echo
	exit
fi

