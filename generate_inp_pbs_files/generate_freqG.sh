#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# gnu sed (gsed)
# find
# wc
# xargs

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

[ -d "geometries/optimized/" ] || printf "\nThe ./geometries/optimized/ \
directory doesnt exist. \n\n" # checks to see if the directory containing
# the optimized geometries of the conformers exists - exits on return 1

cd "geometries/optimized/" # enters that directory

ls -l *.xyz &>/dev/null || printf "\nNo .xyz files detected in the \
./geometries/optimized/ directory. \n\n" # lists all files ending in .xyz 
# and exits on a return 1

numxyz=$(ls -l *.xyz 2>/dev/null | wc -l | xargs) # lists all files ending
# in .xyz and pipes it into wc which counts the  number of files in the ls 
# output and pipes to xargs which removes the leading spaces from wc output

echo
echo "${numxyz}" optimized conformers detected in ./geometries/optimized/

cd ../.. # returns to regular working directory

# Exits script if template files don't exist or path to them can't be found
if [ ! -f "template_inppbs/template_freq.inp" ] || [ ! -f \
"template_inppbs/template_freq.pbs" ]; then
    echo
    echo The filepath is broken or file is missing for one or both of:
    echo
	echo ./template_inppbs/template_freq.inp
    echo ./template_inppbs/template_freq.pbs 
	echo
	exit
fi

[ -d "conformer_files/" ] || mkdir "conformer_files/" # generates the directory
# to hold all of the conformer computational files if it doesn't already exist

echo
echo To generate freq.inp and freq.pbs files for talapas, 
echo choose a conformer library:
echo
echo NOTE: It is not recommended to generate freq.pbs and freq.inp files for
echo every conformer unless there are only around 120 conformers total.
echo


i=0
unset options # clears variable for use
while IFS= read -r -d $'\0' f; do # reads the input from "find" - null 
# delimited (-d $'\0')
        options[i++]="${f}" # saves input from "find" to options variable
done < <(find ./tmpfiles \( ! -regex '.*/\..*' \) -maxdepth 1 -type f -name \
"reduced*.csv" -print0 ) # searches /dir/ and no deeper (maxdepth = 1) for 
# files with the reduced*.csv name and prints them delimited by the null 
# character (-print0)

select opt in "${options[@]}" \
"Use all ${numxyz} conformers (not recommended)" "Exit script"; do 
# lookup select and case tutorials for explanation - bottom line: this
# creates a simple user menu
	case $opt in 
		*.csv) 
			echo
			echo You selected the reduced conformer library "${opt}" 
			library="${opt}" # saves selected library file for use later
			exitcode="reduced" # provides a key for upcoming if then statement
			echo 
			break
			;; 
		"Use all ${numxyz} conformers (not recommended)") 
			echo
			echo You chose to generate freq.inp and freq.pbs files for every \
            conformer.
			exitcode="all" # provides a key for upcoming if then statement
			echo 
			break 
			;; 
		"Exit script") 
			echo
			echo Exiting script. 
			echo 
			exit 
			;; 
		*) # if user attempts to enter something other than one of the 
        # available options, they're prompted to try again
			echo
			echo "This is not an option. Try again."
			echo 
			;; 
	esac # "case" backwards (like if & fi or do & done)
done

# makes directories for each of the conformers for gaussian calculations
if [ ${exitcode} = "reduced" ]; then
	for conf in $(<${library}); do
		conf="${conf##*/}"
		conf="${conf%.*}"
		[ -d "conformer_files/${conf}/" ] || mkdir "conformer_files/${conf}/" 
	done
elif [ ${exitcode} = "all" ]; then
	for conf in ./geometries/optimized/*.xyz; do
		conf="${conf##*/}"
		conf="${conf%_opt*}"
		[ -d "conformer_files/${conf}/" ] || mkdir "conformer_files/${conf}/"
	done
fi

# Saves template file locations to variables
inptemplate="template_inppbs/template_freq.inp"
pbstemplate="template_inppbs/template_freq.pbs"

# freq.inp and freq.pbs file creation
echo Generating freq.inp and freq.pbs files for each conformer...
echo
for confdir in ./conformer_files/*; do
	confdir="${confdir##*files/}"
	confdir="${confdir%/*}"
	if [ ! -f "conformer_files/${confdir}/${confdir}_freq.inp" ] && \
    [ ! -f "conformer_files/${confdir}/${confdir}_freq.pbs" ]; then
		if [ ! -f "geometries/optimized/${confdir}_opt.xyz" ]; then
			echo "ERROR: Missing file ./geometries/optimized/${confdir}_opt.xyz"
		else
			cp -nv "${inptemplate}" \
            "conformer_files/${confdir}/${confdir}_freq.inp"

			cp -nv "${pbstemplate}" \
            "conformer_files/${confdir}/${confdir}_freq.pbs"

			cat "geometries/optimized/${confdir}_opt.xyz" >> \
            "conformer_files/${confdir}/${confdir}_freq.inp" # entire .xyz file 
            # is written to freq.inp

			gsed -i '10,14d' "conformer_files/${confdir}/${confdir}_freq.inp"
            # removes lines 10 - 14

			echo -e '\n \n' >> "conformer_files/${confdir}/${confdir}_freq.inp" 
            # two new lines are added to the end of freq.inp
            # (gaussian requirement)

			gsed -i "s/PLACEHOLDER/${confdir}/g" \
            "conformer_files/${confdir}/${confdir}_freq.inp" # replaces all 
            # instances of "PLACEHOLDER" with filename in freq.inp
            
			gsed -i "s/PLACEHOLDER/${confdir}/g" \
            "conformer_files/${confdir}"/"${confdir}_freq.pbs" # replaces all 
            # instances of "PLACEHOLDER" with filename in freq.pbs
		fi
	else
		echo "ERROR: Existing file(s) ${confdir}_freq.inp and/or" \
        "${confdir}_freq.pbs" # overwrite protection for existing
        # .inp or .pbs files without exiting loop/scipt
	fi
done
echo Done.
echo

echo freq calculations are ready to submit to Talapas.
echo

