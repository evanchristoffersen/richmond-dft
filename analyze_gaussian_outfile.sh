#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# find

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

echo
COLUMNS=1
select opt in "Check .out file(s) for normal termination" "Extract the energy from a single .out file" "Extract the energy from a batch of .out files" "Extract optimized molecular coordinates from a single .out file" "Extract optimized molecular coordinates from a batch of .out files" "Extract all quotes from normally terminated .out files" "Exit script"; do # lookup select and case tutorials for explanation
	case $opt in 
		"Check .out file(s) for normal termination")
			exitcode="termchk"
			break
			;;
		"Extract the energy from a single .out file")
			exitcode="pullenergy"
			break
			;;
		"Extract the energy from a batch of .out files")
			exitcode="pullenergies"
			break
			;;
		"Extract optimized molecular coordinates from a single .out file")
			exitcode="pullcoord"
			break
			;;
		"Extract optimized molecular coordinates from a batch of .out files")
			exitcode="pullcoords"
			break
			;;
		"Extract all quotes from normally terminated .out files")
			exitcode="quotes"
			break
			;;
		"Exit script") 
			echo
			echo Exiting script. 
			echo 
			exit 
			;; 
		*) # if user attempts to enter something other than one of the available options, they're prompted to try again
			echo
			echo "This is not an option. Try again."
			echo 
			;; 
	esac # "case" backwards (like if & fi or do & done)
done

if [ ${exitcode} = "termchk" ]; then
	~/bin/dft_scripts/check_termination.sh
elif [ ${exitcode} = "pullenergy" ]; then
	~/bin/dft_scripts/pull_opt_energy.sh
elif [ ${exitcode} = "pullenergies" ]; then
	~/bin/dft_scripts/pull_opt_energyG.sh
elif [ ${exitcode} = "pullcoord" ]; then
	~/bin/dft_scripts/pull_standard_orientation.sh
elif [ ${exitcode} = "pullcoords" ]; then
	~/bin/dft_scripts/pull_standard_orientationG.sh
elif [ ${exitcode} = "quotes" ]; then
	~/bin/dft_scripts/pull_gaussianquote.sh
fi


