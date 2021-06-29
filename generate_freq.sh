#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# cat
# extended test [[ ]]
# gnu sed (gsed)

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

# Asks user for the starting conformer file (requires xyz file format)
echo
echo Enter the molecular coordinate file \(xyz file format required\):
read -e filename
echo

# Exits script if the file specified by the user isn't found
[ -f ${filename} ]

# Shortens filename to disclude extensions
sfilename=${filename%.*}
sfilename=${sfilename%%_opt*}

# Sets up regular expression parameters to include only real numbers 
re="^[+-]?[0-9]+([.][0-9]+)?$"

# Overwrite protection for existing freq.inp files
if [ -f "${sfilename}_freq.inp" ]; then
	echo "${sfilename}_freq.inp" already exists.
	echo Exiting script to prevent file overwrite.
	echo
	exit
fi

# Overwrite protection for existing freq.pbs file
if [ -f "${sfilename}_freq.pbs" ]; then 
	echo "${sfilename}_freq.pbs" already exists.
	echo Exiting script to prevent file overwrite.
	echo
	exit
fi

echo Enter molecular charge: # allow user to specify charge
read charge
echo
if ! [[ "${charge}" =~ ${re} ]]; then # uses regular expression to check input
# is a real number 
	echo Error: You did not enter a number.
	echo Exiting script.
	echo
	exit
fi

echo Enter molecular multiplicity: # allow user to specify multiplicity
read mult
echo
if ! [[ "${mult}" =~ ${re} ]]; then # uses regular expression to check
# input is a real number 
	echo Error: You did not enter a number.
	echo Exiting script.
	echo
	exit
fi



# --- WRITE CONTENTS OF .inp FILE TO FILE ---

echo '%NProcShared=12
%mem=12GB
%rwf=/tmp/PLACEHOLDER_freq/,-1
%chk=/tmp/PLACEHOLDER_freq/PLACEHOLDER_freq.chk
#T B3LYP/6-311++G(2d,2p) Freq(HPModes) scf(tight)  

 Gaussian09 freq calc of PLACEHOLDER using B3LYP/6-311++G(2d,2p)
' > "${sfilename}_freq.inp" # writes header to freq.inp file

echo "${charge} ${mult}" >> "${sfilename}_freq.inp" # appends charge and 
# multiplicity to freq.inp file
cat "${filename}" >> "${sfilename}_freq.inp" # appends entire .xyz file
# to freq.inp file
gsed -i '10,11d' "${sfilename}_freq.inp" # removes lines 10 - 11
echo -e '\n \n' >> "${sfilename}_freq.inp" # appends two new lines to end
# of file (gaussian requirement)
# replaces all instances of "PLACEHOLDER" with sfilename
gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_freq.inp"



# --- WRITE CONTENTS OF .pbs FILE TO FILE ---

echo '#!/bin/bash
#SBATCH --output="PLACEHOLDER_freq.out"
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --export=ALL
#SBATCH --time=0-24:00:00
#SBATCH --error=PLACEHOLDER_freq.err

hostname

# Create scratch directory here:
test -d /tmp/PLACEHOLDER_freq || mkdir -v /tmp/PLACEHOLDER_freq

# Activate Gaussian:
#export g09root=/usr/local/packages/gaussian
#. $g09root/g09/bsd/g09.profile
module load gaussian

which g09

g09 < PLACEHOLDER_freq.inp > PLACEHOLDER_freq.out

# Copy checkpoint file from local scratch to working directory after job completes:
cp -pv /tmp/PLACEHOLDER_freq/PLACEHOLDER_freq.chk .

# Clean up scratch:
rm -rv /tmp/PLACEHOLDER_freq
' > "${sfilename}_freq.pbs" # writes header to freq.pbs file

gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_freq.pbs" # replaces 
# all instaces of "PLACEHOLDER" with sfilename



echo Ready to submit to talapas for frequency calculation.
echo

