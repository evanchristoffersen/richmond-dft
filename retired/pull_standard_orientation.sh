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
echo WARNING: This script will not correctly write a new .xyz file if your molecule contains atoms larger than Calcium.
echo 'Enter (y) to continue, or (n) to exit script:'
read q

if ! [ ${q} = 'y' ]; then
	echo
	echo Exiting script.
	echo
	exit 0
fi

unset q # resets variable so it can be used again later

echo
echo Enter gaussian.out filename:
read -e f
echo

# Exits script if file doesn't exist
if [ ! -f ${f} ]; then
	echo "${f}" does not exist.
	echo Exiting script.
	echo
	exit 0
fi

# Exits script if Gaussian didn't terminate normally
if ! grep -q "Normal termination of Gaussian 09 at" "${f}"; then
	echo "${f}" did not terminate normally.
	echo Do you still want to try to pull the last set of coordinates from the .out file?
	echo 'Enter (y) to attempt coordinate extraction, or (n) to exit script:'
	read q
	echo
	if ! [ ${q} = 'y' ]; then
		echo Exiting script.
		echo
		exit 0
	else
		opt=no
	fi
fi

unset q

# Pulls the energy of the optimized structure to be reported at the end of the script
if ! [ ${opt} = 'no' ]; then
	a=$(gsed -n "/GINC/,/\@/p" ${f})
	a=$(echo ${a//[$'\t\r\n ']})
	a=${a#*HF=}
	a=${a%\\RMSD*}
fi

# Filename becomes everything after the last "/" but before the ".out"
if ! [ ${opt} = 'no' ]; then
	f2="${f##*/}"
	f2="${f2%.*}"
elif [ ${opt} = 'no' ]; then
	f2="${f##*/}"
	f2="${f2%_opt*}"
	f2="${f2}_PARTIAL_OPT"
fi

if [ -f ./"${f2}".xyz ]; then
	echo Previously generated coordinate file detected: ./"${f2}".xyz
	echo Exiting script to prevent file overwrite.
	echo
	exit 0
fi

mkdir ./tmp/

# Optimized coordinate extraction
# Combining the following three commands trips the non zero exit error, so it is necessary to split the tac, gsed, and tac commands into three separate lines
# tac "${f}" | gsed '/Rotational\ constants/,$!d;/Standard\ orientation\:/q' | tac >> ./tmp/tmp.txt # Copies optimized geometry table from .out file
tac "${f}" >> ./tmp/tmp.txt
gsed '/Rotational\ constants/,$!d;/Standard\ orientation\:/q' ./tmp/tmp.txt >> ./tmp/tmp2.txt
tac ./tmp/tmp2.txt >> ./tmp/tmp3.txt

gsed -i '1,5d' ./tmp/tmp3.txt # removes the first five lines of the table
gsed -i '$d' ./tmp/tmp3.txt # removes the last two lines of the table
gsed -i '$d' ./tmp/tmp3.txt
awk '{print $2, $4, $5, $6}' ./tmp/tmp3.txt >> ./tmp/tmp4.txt # pulls out the 2nd, 4th, 5th, and 6th columns

# calculate_rmsd cannot read the atom identity from its atomic mass number (unlike Gaussian or Avogadro)
# The gsed statements below replace the atomic numbers with their letter abbreviation
# H comes last because if this gsed command came before Ne (for instance), it would replace the "1" in "10" with an "H"
gsed -i '1,$s/^20/Ca/' ./tmp/tmp4.txt # From line 2 to the end of the file, if the atomic number is found in the first character of a line replace it with its letter abbreviation
gsed -i '1,$s/^19/K\ /' ./tmp/tmp4.txt
gsed -i '1,$s/^18/Ar/' ./tmp/tmp4.txt
gsed -i '1,$s/^17/Cl/' ./tmp/tmp4.txt
gsed -i '1,$s/^16/S\ /' ./tmp/tmp4.txt
gsed -i '1,$s/^15/P\ /' ./tmp/tmp4.txt
gsed -i '1,$s/^14/Si/' ./tmp/tmp4.txt
gsed -i '1,$s/^13/Al/' ./tmp/tmp4.txt
gsed -i '1,$s/^12/Mg/' ./tmp/tmp4.txt
gsed -i '1,$s/^11/Na/' ./tmp/tmp4.txt
gsed -i '1,$s/^10/Ne/' ./tmp/tmp4.txt
gsed -i '1,$s/^9/F/' ./tmp/tmp4.txt
gsed -i '1,$s/^8/O/' ./tmp/tmp4.txt
gsed -i '1,$s/^7/N/' ./tmp/tmp4.txt
gsed -i '1,$s/^6/C/' ./tmp/tmp4.txt
gsed -i '1,$s/^5/B/' ./tmp/tmp4.txt
gsed -i '1,$s/^4\ /Be/' ./tmp/tmp4.txt
gsed -i '1,$s/^3\ /Li/' ./tmp/tmp4.txt
gsed -i '1,$s/^2\ /He/' ./tmp/tmp4.txt
gsed -i '1,$s/^1/H/' ./tmp/tmp4.txt

# This fixes the spacing between the columns in the xyz file
# It came from: https://unix.stackexchange.com/questions/398483/decimal-centered-columns-unix  
awk '{ printf "%-6s ", $1; for (i=2; i<=NF; i++) printf "%15.6f ", $i; printf "\n"; }' ./tmp/tmp4.txt >> ./tmp/tmp5.txt

# gsed commands written with "@" as the delimiter
gsed -i "1s@^@${f2}.xyz\n@" ./tmp/tmp5.txt
gsed -i "1s@^@$(($(gwc -l < ./tmp/tmp5.txt)-1))\n@" ./tmp/tmp5.txt

mv ./tmp/tmp5.txt ./${f2}.xyz
rm -r ./tmp/

if [ ${opt} = 'yes' ]; then
	echo The energy of your optimized structure is: "${a}" Hartrees
	echo
fi

# if [ ${opt} = 'no' ]; then
# 	echo Would you like to prepare a new set of input files using the partial optimization?
# 	echo 'Enter (y) or (n):'
# 	read q
# 	echo
# 	if [ ${q} = 'y' ]; then
# 		mkdir DIRECTORY
# 		mv *.err *.inp *.out *.pbs *.chk DIRECTORY
# 		UNFINISHED
# 	fi
# fi

