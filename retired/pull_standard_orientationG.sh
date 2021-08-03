#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# gnu sed (gsed)
# gnu wc (gwc)
# grep
# tac

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

# Warns user that script is only written to handle atoms up to atomic number 20
echo
echo WARNING: This script will fail if your molecule contains atoms larger than Ca.
echo Continue? \(Enter y or n\)
read q

if ! [ ${q} = y ]; then
	echo
	echo Exiting script.
	echo
	exit
fi

# Makes a directory for the optimized geometries if it doesn't already exist
if [[ ! -d ./geometries/ && ! -d ./geometries/optimized/ ]]; then
	mkdir ./geometries
	mkdir ./geometries/optimized/
elif [ ! -d ./geometries/optimized/ ]; then
	mkdir ./geometries/optimized/
else
	:
fi

# Checks if the conformer_files/ directory exists, and if there are any existing .out files inside of it. If one or both isn't true - exits script
if [ ! -d ./conformer_files/ ]; then
	echo No gaussian_opt.out files detected in ./conformer_files/ or any of its subdirectories.
	echo Exiting script.
	echo
	exit
# elif [ ! -d ./conformer_files/conf*/ ]; then # this doesnt work - raises a too many arguments error. See next line for code that does work
elif dirtest=( ./conformer_files/conf*/ ) && [[ ! -d ${dirtest[0]} ]]; then
	echo No gaussian_opt.out files detected in ./conformer_files/ or any of its subdirectories.
	echo Exiting script.
	echo
	exit
else
	:
fi

# Makes a temporary directory called tmp/ inside the ./tmpfiles/ directory
if [ ! -d ./tmpfiles/ ]; then
	mkdir ./tmpfiles/
	mkdir ./tmpfiles/tmp/
elif [ ! -d ./tmpfiles/tmp/ ]; then
	mkdir ./tmpfiles/tmp/
else
	:
fi

for f in ./conformer_files/conf*/*_opt.out; do
			f2="${f##*/}"
			f2="${f2%.*}" # filename becomes everything after the last "/" but before the ".out"

	# Check if output file terminated normally
	if [ ! -f ./geometries/optimized/"${f2}.xyz" ]; then
		if ! grep -q "Normal termination of Gaussian 09 at" "${f}"; then
			echo Skipping "${f}" because gaussian did not terminate normally.
		else # Optimized coordinate extraction
			# Combining the following three commands trips the non zero exit error, so it is necessary to split the tac, gsed, and tac commands into three separate lines
			# tac "${f}" | gsed '/Rotational\ constants/,$!d;/Standard\ orientation\:/q' | tac >> ./tmp/tmp.txt # Copies optimized geometry table from .out file
			tac "${f}" >> ./tmpfiles/tmp/tmp.txt
			gsed '/Rotational\ constants/,$!d;/Standard\ orientation\:/q' ./tmpfiles/tmp/tmp.txt >> ./tmpfiles/tmp/tmp2.txt
			tac ./tmpfiles/tmp/tmp2.txt >> ./tmpfiles/tmp/tmp3.txt

			gsed -i '1,5d' ./tmpfiles/tmp/tmp3.txt # removes the first five lines of the table
			gsed -i '$d' ./tmpfiles/tmp/tmp3.txt # removes the last two lines of the table
			gsed -i '$d' ./tmpfiles/tmp/tmp3.txt
			awk '{print $2, $4, $5, $6}' ./tmpfiles/tmp/tmp3.txt >> ./tmpfiles/tmp/tmp4.txt # pulls out the 2nd, 4th, 5th, and 6th columns

			# calculate_rmsd cannot read the atom identity from its atomic mass number (unlike Gaussian or Avogadro)
			# The gsed statements below replace the atomic numbers with their letter abbreviation
			# H comes last because if this gsed command came before Ne (for instance), it would replace the "1" in "10" with an "H"
			gsed -i '1,$s/^20/Ca/' ./tmpfiles/tmp/tmp4.txt # From line 2 to the end of the file, if the atomic number is found in the first character of a line replace it with its letter abbreviation
			gsed -i '1,$s/^19/K\ /' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^18/Ar/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^17/Cl/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^16/S\ /' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^15/P\ /' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^14/Si/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^13/Al/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^12/Mg/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^11/Na/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^10/Ne/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^9/F/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^8/O/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^7/N/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^6/C/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^5/B/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^4\ /Be/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^3\ /Li/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^2\ /He/' ./tmpfiles/tmp/tmp4.txt
			gsed -i '1,$s/^1/H/' ./tmpfiles/tmp/tmp4.txt
			
			# This fixes the spacing between the columns in the xyz file
			# It came from: https://unix.stackexchange.com/questions/398483/decimal-centered-columns-unix  
			awk '{ printf "%-6s ", $1; for (i=2; i<=NF; i++) printf "%15.6f ", $i; printf "\n"; }' ./tmpfiles/tmp/tmp4.txt >> ./tmpfiles/tmp/tmp5.txt

			# gsed commands written with "@" as the delimiter
			gsed -i "1s@^@${f2}.xyz\n@" ./tmpfiles/tmp/tmp5.txt
			gsed -i "1s@^@$(($(gwc -l < ./tmpfiles/tmp/tmp5.txt)-1))\n@" ./tmpfiles/tmp/tmp5.txt
			
			mv ./tmpfiles/tmp/tmp5.txt ./geometries/optimized/"${f2}.xyz"
			rm ./tmpfiles/tmp/*.txt
		fi
	else
		echo Skipping "${f}" due to existing geometry file in ./geometries/optimized/.
	fi
done

rm -r ./tmpfiles/tmp/ 

echo 
echo Optimized geometries pulled from gaussian_opt.out files into .xyz format in ./geometries/optimized/
echo

