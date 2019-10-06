#!/bin/bash
#genEvtSelTxt.sh for TAROGE-Melbourne
#S.H. Wang 2019-02
#
#The script generate text file for setting cut thresholds of event selection, defined in TarogeMEventSelection.cpp. A timestamp in UTC is attached in file name so Taroge-M can sort and archive
############### This script should be udpated manually according to version of TarogeMEventSelection.cpp
#assuming user PCs has good time keeping
#
#const Char_t* const kSelKeyword[kNSelection] = {	//for reading threshold
#	"HVRatio",
#	"SatComm",
#	"HighWind",
#	"MaxLBPRatio",
#	"HpolVeto"
#};
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"
TimeString=$( date -u '+%Y%0m%0d-%H%0M%0SZ')  
#should be consistent with processQueueConfig.sh
EvtSelTitle="EvtSel"
NSelection=5

#if [ $# -ne $(${NSelection}+1)  ] ; then
if [ $# -ne ${NSelection}  ] ; then
	echo "arguments: [HVRatio in dB] [SatComm ratio in dB] [HighWind ratio in dB] [MaxLBPRatio [0,1] ] [HpolVeto in mag] "	#[output dir]
	echo "Number of arguements should match number of selections ${NSelection}. exit"
	exit 1
else
	#check range?

#	HVRatio	4.0
#	SatComm	-0.3
#	HighWind	1.4
#	MaxLBPRatio	0.5
#	HpolVeto	1.0
	selfile=${EvtSelTitle}-${TimeString}.txt
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: generating ${selfile}"
	echo "$# = ${NSelection} "
	echo "HVRatio	$1" > ${selfile}
	echo "SatComm	$2" >> ${selfile}
	echo "HighWind	$3" >> ${selfile}
	echo "MaxLBPRatio	$4" >> ${selfile}
	echo "HpolVeto	$5" >> ${selfile}

fi
#file prefix for recognizing file type in folders


echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"

