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

# Overwrite protection for existing hf.inp files
if [ -f "${sfilename}_hf.inp" ]; then
	echo "${sfilename}_hf.inp" already exists.
	echo Exiting script to prevent file overwrite.
	echo
	exit
fi

# Overwrite protection for existing hf.pbs file
if [ -f "${sfilename}_hf.pbs" ]; then 
	echo "${sfilename}_hf.pbs" already exists.
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
if ! [[ "${mult}" =~ ${re} ]]; then # uses regular expression to check input is
# a real number
	echo Error: You did not enter a number.
	echo Exiting script.
	echo
	exit
fi



# --- WRITE CONTENTS OF .inp FILE TO FILE ---

echo '%NProcShared=12
%mem=12GB
%rwf=/tmp/PLACEHOLDER_hf/,-1
%chk=/tmp/PLACEHOLDER_hf/PLACEHOLDER_hf.chk
#P HF/6-31g* OPT(Tight) scf(tight)

 Gaussian09 HF opt of PLACEHOLDER_hf using HF/6-31g*
' > "${sfilename}_hf.inp" # writes header to hf.inp file

echo "${charge} ${mult}" >> "${sfilename}_hf.inp" # writes charge and 
# multiplicity to hf.inp file
cat "${filename}" >> "${sfilename}_hf.inp" # writes entire .xyz file to
# hf.inp file
gsed -i '10,11d' "${sfilename}_hf.inp" # removes lines 10 - 11
echo -e '\n \n' >> "${sfilename}_hf.inp" # adds two new lines to end of file
# (gaussian requirement)
gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_hf.inp" # replaces all
# instances of "PLACEHOLDER" with sfilename



# --- WRITE CONTENTS OF .pbs FILE TO FILE ---

echo '#!/bin/bash
#SBATCH --output="PLACEHOLDER_hf.out"
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --export=ALL
#SBATCH --time=0-24:00:00
#SBATCH --error=PLACEHOLDER_hf.err

hostname

# Create scratch directory here:
test -d /tmp/PLACEHOLDER_hf || mkdir -v /tmp/PLACEHOLDER_hf

# Activate Gaussian:
#export g09root=/usr/local/packages/gaussian
#. $g09root/g09/bsd/g09.profile
module load gaussian

which g09

g09 < PLACEHOLDER_hf.inp > PLACEHOLDER_hf.out

# Copy checkpoint file from local scratch to working directory after job completes:
cp -pv /tmp/PLACEHOLDER_hf/PLACEHOLDER_hf.chk .

# Clean up scratch:
rm -rv /tmp/PLACEHOLDER_hf
' > "${sfilename}_hf.pbs" # writes header to hf.pbs file

gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_hf.pbs" # replaces all
# instances of "PLACEHOLDER" with sfilename



echo Ready to submit to talapas for hartree fock calculation.
echo

