#!/usr/bin/env bash

# Non-posix compliant tools used in this script:
# gnu sed (gsed)
# gnu awk (gawk)
# grep
# find

# abort on nonzero exit status
set -o errexit 
# abort on unbound variable
set -o nounset
# dont hide errors within pipes
set -o pipefail

echo
for outfile in $(find . \( ! -regex '.*/\..*' \) -type f -name "*.out"); do
	if grep -q "Normal termination of Gaussian" "${outfile}"; then
		echo "${outfile}" Terminated normally.
		quote=$(gsed -n "/\\\@/,/Job cpu time/p" "${outfile}")
		quote="${quote%Job*}"
		quote="${quote##*\@}"
		echo "${quote}" >> ~/gaussianquotes.txt
		echo
	else
		echo "${outfile}" Did NOT terminate normally.
		echo
	fi
done

gawk -i inplace '!NF || ! a[$0]++' ~/gaussianquotes.txt
gsed -i '/^$/N;/^\n$/D' ~/gaussianquotes.txt
# tac < ~/gaussianquotes.txt | sed '/[^[:blank:]]/,$!d' | tac
# gsed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' ~/gaussianquotes.txt
# gsed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' ~/gaussianquotes.txt
# awk 'NF {p=1} p' <<< "$(< ~/gaussianquotes.txt)"
# cat -s ~/gaussianquotes.txt

