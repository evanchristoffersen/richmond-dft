#!/usr/bin/env bash

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

# This counts the number of the files ending in .xyz
# But because the output of wc has leading spaces, we use tr -d ' ' to trim those
filecount=$(ls *.xyz | wc -l | tr -d ' ')

echo The following conformer files have been detected by this script.
echo Please review the list and make sure these are the conformers you wish to compare.
echo

ls -1 *.xyz

echo Continue \(y/n\)?
read pause
echo

if [ "${pause}" = n ]; then
	exit
elif [ "${pause}" = y ]; then
	:
else
	exit
fi

start=$(date +%s)

if [ "${filecount}" -gt 20 ]; then
	echo WARNING: With "${filecount}" conformer files, this script may take several minutes to run.
	echo 30 Conformers = ~3 minute run time
	echo Note: The comparison process gets faster the fewer conformers there are left.
	echo
fi

# This checks if the duplicate_check_rmsd_logs directory already exists
# If not it makes the directory
if [ ! -d "./duplicate_check_rmsd_logs" ]; then
	mkdir duplicate_check_rmsd_logs
else
	echo WARNING:
	echo Previously generated directory holding the rmsd log files has been detected as duplicate_check_rmsd_logs/.
	echo This script will not overwrite any existing data in these log files, but it will append more data to them.
	echo Be careful when reviewing your results that you don\'t confuse old rmsd values with current ones.
	echo
fi

# The loop below runs each conformer.xyz file through the calculate_rmsd program
# It does not compare a file with itself (f1-f1 forbidden)
# It does not compare two files more than once (if f1-f2, then f2-f1 is forbidden)
# In the future should you need to make the pair f1-f2 different than f2-f1, merely remove the "shift" utility on line 53 
# In truth it isn't clear to me the exact function of "set" and "shift"
# Results of the calculate_rmsd program are saved to log files
# RMSD cut off values were determined whimsically. Feel free to change them as needed.
dupecount=0
set -- *.xyz
for f1; do
	echo Scanning ${f1}...
	shift
	for f2; do
		rmsd=$(calculate_rmsd "${f1}" "${f2}")
		if [[ $(echo "${rmsd} <= 0.1" | bc) -ne 0 ]]; then
			echo "${f1}" and "${f2}" have a low rmsd.
			echo "${f1}" and "${f2}" >> ./duplicate_check_rmsd_logs/lowrmsd_log.txt
			echo rmsd: "${rmsd}" >> ./duplicate_check_rmsd_logs/lowrmsd_log.txt
			echo "" >> ./duplicate_check_rmsd_logs/lowrmsd_log.txt
			${dupecount}=$((${dupecount}+1))
		elif [[ $(echo "${rmsd} > 0.1" | bc) -ne 0 && $(echo "${rmsd} <= 0.5" | bc) -ne 0 ]]; then
			echo "${f1}" and "${f2}" >> ./duplicate_check_rmsd_logs/midlowrmsd_log.txt
			echo rmsd: "${rmsd}" >> ./duplicate_check_rmsd_logs/midlowrmsd_log.txt
			echo "" >> ./duplicate_check_rmsd_logs/midlowrmsd_log.txt
		elif [[ $(echo "${rmsd} > 0.5" | bc) -ne 0 && $(echo "${rmsd} <= 1.0" | bc) -ne 0 ]]; then
			echo "${f1}" and "${f2}" >> ./duplicate_check_rmsd_logs/midhighrmsd_log.txt
			echo rmsd: "${rmsd}" >> ./duplicate_check_rmsd_logs/midhighrmsd_log.txt
			echo "" >> ./duplicate_check_rmsd_logs/midhighrmsd_log.txt
		else
			echo "${f1}" and "${f2}" >> ./duplicate_check_rmsd_logs/highrmsd_log.txt
			echo rmsd: "${rmsd}" >> ./duplicate_check_rmsd_logs/highrmsd_log.txt
			echo "" >> ./duplicate_check_rmsd_logs/highrmsd_log.txt
		fi
	done
	echo Done.
	echo
done

echo
echo "${dupecount}" potential duplicate\(s\) detected.
echo See lowrmsd\_log.txt for the conformer names of any potential duplicates.
echo

end=$(date +%s)
duration=$(echo "$end - $start" | bc)
echo Total run time: "$duration" seconds
echo

