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

# Overwrite protection for existing opt.inp file
if [ -f "./${sfilename}_opt.inp" ]; then
	echo "${sfilename}_opt.inp" already exists.
	echo Exiting script to prevent file overwrite.
	echo
	exit
fi

# Overwrite protection for existing opt.pbs file
if [ -f "./${sfilename}_opt.pbs" ]; then 
	echo "${sfilename}_opt.pbs" already exists.
	echo Exiting script to prevent file overwrite.
	echo
	exit
fi

echo Enter molecular charge: # allow user to specify charge
read charge
echo
if ! [[ "${charge}" =~ ${re} ]]; then # uses regular expression to check input is
# a real number
	echo Error: You did not enter a number.
	echo Exiting script.
	echo
	exit
fi

echo Enter molecular multiplicity: # allow user to specify multiplicity
read mult
echo
if ! [[ "${mult}" =~ ${re} ]]; then # uses regular expression to check input is a
# real number
	echo Error: You did not enter a number.
	echo Exiting script.
	echo
	exit
fi



# --- WRITE CONTENTS OF .inp FILE TO FILE ---

echo '%NProcShared=12
%mem=12GB
%rwf=/tmp/PLACEHOLDER_opt/,-1
%chk=/tmp/PLACEHOLDER_opt/PLACEHOLDER_opt.chk
#T B3LYP/6-311++G(2d,2p) OPT(Tight) scf(tight)

 Gaussian09 opt calc of PLACEHOLDER using B3LYP/6-311++G(2d,2p)
' > "${sfilename}_opt.inp" # writes header to opt.inp file

echo "${charge} ${mult}" >> "${sfilename}_opt.inp" # writes charge and
# multiplicity to opt.inp file
cat "${filename}" >> "${sfilename}_opt.inp" # writes entire .xyz file to
# opt.inp file
gsed -i '10,11d' "${sfilename}_opt.inp" # removes lines 10 - 11 
echo -e '\n \n' >> "${sfilename}_opt.inp" # adds two new lines to end of file
# (gaussian requirement)
gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_opt.inp" # replaces all
# instances of "PLACEHOLDER" with sfilename



# --- WRITE CONTENTS OF .pbs FILE TO FILE ---

echo '#!/bin/bash
#SBATCH --output="PLACEHOLDER_opt.out"
#SBATCH --partition=short
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --export=ALL
#SBATCH --time=0-24:00:00
#SBATCH --error=PLACEHOLDER_opt.err

hostname

# Create scratch directory here:
test -d /tmp/PLACEHOLDER_opt || mkdir -v /tmp/PLACEHOLDER_opt

# Activate Gaussian:
#export g09root=/usr/local/packages/gaussian
#. $g09root/g09/bsd/g09.profile
module load gaussian

which g09

g09 < PLACEHOLDER_opt.inp > PLACEHOLDER_opt.out

# Copy checkpoint file from local scratch to working directory after job completes:
cp -pv /tmp/PLACEHOLDER_opt/PLACEHOLDER_opt.chk .

# Clean up scratch:
rm -rv /tmp/PLACEHOLDER_opt
' > "${sfilename}_opt.pbs" # writes header to opt.pbs file

gsed -i "s/PLACEHOLDER/${sfilename}/g" "${sfilename}_opt.pbs" # replaces all
# instances of "PLACEHOLDER" with sfilename



echo Ready to submit to talapas for geometry optimization.
echo

