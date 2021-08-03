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

# overwrite protection for existing anharm.inp files
if [ -f "${sfilename}_anharm.inp" ]; then
	echo "${sfilename}_anharm.inp" already exists.
	echo Exiting script to prevent file overwrite.
	echo
	exit
fi

# Overwrite protection for existing anharm.pbs file
if [ -f "${sfilename}_anharm.pbs" ]; then 
	echo "${sfilename}_anharm.pbs" already exists.
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
%rwf=/tmp/PLACEHOLDER_anharm/,-1
%chk=/tmp/PLACEHOLDER_anharm/PLACEHOLDER_anharm.chk
#T B3LYP/6-311++G(2d,2p) Freq(Anharmonic) scf(tight)  

 Gaussian09 anharm calc of PLACEHOLDER using B3LYP/6-311++G(2d,2p)
' > "${sfilename}_anharm.inp" # writes header to anharm.inp file

echo "${charge} ${mult}" >> "${sfilename}_anharm.inp" # appends charge and
# multiplicity to anharm.inp file
cat "${filename}" >> "${sfilename}_anharm.inp" # appends entire .xyz file
# to anharm.inp file
gsed -i '10,11d' "${sfilename}_anharm.inp" # removes lines 10 - 11
echo -e '\n \n' >> "${sfilename}_anharm.inp" # appends two new lines to end
# of file (gaussian requirement)
# replaces all instances of "PLACEHOLDER" with sfilename
gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_anharm.inp"



# --- WRITE CONTENTS OF .pbs FILE TO FILE ---

echo '#!/bin/bash
#SBATCH --output="PLACEHOLDER_anharm.out"
#SBATCH --partition=long
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --export=ALL
#SBATCH --time=0-96:00:00
#SBATCH --error=PLACEHOLDER_anharm.err

hostname

# Create scratch directory here:
test -d /tmp/PLACEHOLDER_anharm || mkdir -v /tmp/PLACEHOLDER_anharm

# Activate Gaussian:
#export g09root=/usr/local/packages/gaussian
#. $g09root/g09/bsd/g09.profile
module load gaussian

which g09

g09 < PLACEHOLDER_anharm.inp > PLACEHOLDER_anharm.out

# Copy checkpoint file from local scratch to working directory after job completes:
cp -pv /tmp/PLACEHOLDER_anharm/PLACEHOLDER_anharm.chk .

# Clean up scratch:
rm -rv /tmp/PLACEHOLDER_anharm
' > "${sfilename}_anharm.pbs" # writes header to anharm.pbs file

gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_anharm.pbs" # replaces
# all instaces of "PLACEHOLDER" with sfilename



echo Ready to submit to talapas for anharmonics calculation.
echo

