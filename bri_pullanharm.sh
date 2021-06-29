#!/bin/bash -l
file=abvNewCode_big_20c
#confNum=Big20
count=1
#rm anharmList_${confNum}.txt
for line in `cat ${file}.txt`;do
	codeline=$line
	echo "${codeline}"
	echo "${codeline:0:1}"
	numO=`echo $((1+0))`
	{
	if [ "${codeline:0:1}" == "1" ]; then  
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
	fi
	}
        {
        if [ "${codeline:1:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:2:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:3:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
	echo "*** end 1st solvation shell ***"
	{
	if [ "${codeline:4:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
	{
        if [ "${codeline:5:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:6:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:7:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:8:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:9:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:10:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:11:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:12:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:13:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:14:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
        {
        if [ "${codeline:15:1}" == "1" ]; then
		numAdd=`echo $((${numO}+3))`
		numO=${numAdd}
        fi
        }
	echo "end IF"
	numAdd=`echo $((${numO}+2))`
	echo "${codeline} has ${numAdd} atoms"
	cd ${codeline}
	grep -n -F "E(anharm)" h2o_${codeline}_anharm.out >> ${codeline}_anharmLine.txt
#	lastLine=$(wc -l <${codeline}_coords.txt)
	anharmLine=$(awk -F":" 'NR==1{print $1}' ${codeline}_anharmLine.txt)
	echo "anharmLine: $anharmLine"
	anharmNum=${anharmLine}
	echo "anharmNum= ***$anharmNum***"
#	sed -n "${1}p" < ${codeline}_anharmLine.txt >anharmLine
#	lineNum=$(awk -F":" '{print $1}' anharmLine)
#	echo "linNum: ${lineNum}**"
	startLine=`echo $((${anharmNum}+4))`
	stopLine=`echo $((${startLine}+${numAdd}-1))`
	echo "${startLine} to ${stopLine}"
	sed -n "${startLine},${stopLine}p" < h2o_${codeline}_anharm.out > newAnharm
	awk '{ print $4 }' newAnharm >anharmFreqCol
#	cp newAnharm anharmFreq
#	rm newCoord
	cd ../
done

