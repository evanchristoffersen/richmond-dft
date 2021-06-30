#!/usr/bin/env bash

# Non-posix compliant tools used in this script:

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

echo
COLUMNS=1
select opt in "Prepare a single optimization job" "Prepare a single frequency job" "Prepare a single anharmonics job" "Prepare a single Hartree-Fock job" "Prepare batch optimization jobs" "Prepare batch frequency jobs" "Prepare batch anharmonics jobs" "Prepare batch Hartree-Fock jobs" "Exit script"; do # lookup select and case tutorials for explanation
	case $opt in 
		"Prepare a single optimization job")
			exitcode="opts"
			break
			;;
		"Prepare a single frequency job")
			exitcode="freqs"
			break
			;;
		"Prepare a single aharmonics job")
			exitcode="anharms"
			break
			;;
		"Prepare a single Hartree-Fock job")
			exitcode="hfs"
			break
			;;
		"Prepare batch optimization jobs")
			exitcode="optb"
			break
			;;
		"Prepare batch frequency jobs")
			exitcode="freqb"
			break
			;;
		"Prepare batch aharmonics job")
			exitcode="anharmb"
			break
			;;
		"Prepare batch Hartree-Fock jobs")
			exitcode="hfb"
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

if [ ${exitcode} = "opts" ]; then
	~/bin/dft_scripts/generate_opt.sh
elif [ ${exitcode} = "freqs" ]; then
	~/bin/dft_scripts/generate_freq.sh
elif [ ${exitcode} = "anharms" ]; then
	~/bin/dft_scripts/generate_anharm.sh
elif [ ${exitcode} = "hfs" ]; then
	~/bin/dft_scripts/generate_hf.sh
elif [ ${exitcode} = "optb" ]; then
	~/bin/dft_scripts/generate_optG.sh
elif [ ${exitcode} = "freqb" ]; then
	~/bin/dft_scripts/generate_freqG.sh
elif [ ${exitcode} = "anharmb" ]; then
	~/bin/dft_scripts/generate_anharmG.sh
elif [ ${exitcode} = "hfb" ]; then
	~/bin/dft_scripts/generate_hfG.sh
fi

