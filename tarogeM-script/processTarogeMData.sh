#!/bin/bash
# processTarogeMData.sh for TAROGE-Melbourne
# S.H. Wang 2019/01-02
#
#regularly check (probably scheduled by crontab) if new data is coming, running event selection, and generating selected data for transfer via Inmarsat
#save printout to log

#source common variables
. ${TarogeMDir}/TarogeMIOConstant.sh

#${0} for name of this script
#date -u for UTC
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"

#use existing python scripts in SnowShovel
# ${SNS}: path to SnowShovel
#[MAC]/[run]/[seq]


#check if previous script is running
#from stackoverflow
#pidof -- find the process ID of a running program.
#-x     Scripts too - this causes the program to also return process id's of  shells  running  the    named scripts.
for pid in $(pidof -x ${0} ); do
	#exclude the current script
    if [ ${pid} != $$ ]; then
    	#man bash: $$ Expands to the process ID of the shell. In a () subshell, it expands to the process ID of the current shell, not the subshell.
        echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :${0} : Process is already running with PID ${pid} . skip this run."
        exit 1
    fi
done

#it's possible SST Comm window is always overlapped with makeRawTree
if [ "$(cat ${IsSSTCommTxt})" -eq 1 ]; then
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC:  IsSSTCommTxt=1  skip processing Binary data files"
else

	#check binary data directory
	#-z return true if string is NULL; see 'help test'
	#ls -A: do not list implied . and ..
	if [ -z "$(ls -A ${NewBinDataDir})" ]; then
	   echo "Empty Binary data directory"
	else
		#   echo "Not Empty"

		#get all file in the directory

		#make raw tree
		#
		#        print "Usage: python doMakeRawTree.py "\
		#            "[input base directory of raw files] "\
		#            "[output base directory] [bad files base directory]"
		#        print "  --- OR --- "
		#        print "       python doMakeRawTree.py "\
		#           "[text file with space separated variables: "\
		#            "input base dir, output base dir, bad files base dir]"
		    # run makeRawTree.C
		#    args = ["root.exe","-b","-q",
		#            '$SNS/scripts/offline/makeRawTree.C+('\
		#                '"{0}","{1}")'.format(rawfile, outdir)]
		
		#  ------->  the raw tree direcotory has mac/run/seq/ hierarchy
		#	bin data are not moved by the macro
		echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: generatee Raw Tree from binary"
		python ${MakeRawTreeMacro} ${NewBinDataDir} ${NewRawDataDir} ${BadDataDir}


		#create a merged raw data file for easy process
		#hadd -f2 [destination file] [source files]

		#alternative:  text file with file list and TChain
		#use find for all files in subfolders
		#find:   -type f : only files (skip directories);  -name "RawTree*.root" for name pattern
		#export NewRawDataList="${EventSelectDir}/NewRawDataList.txt"
		find ${NewRawDataDir} -type f -name "RawTree*.root" | sort -g >  ${NewRawDataList}

		#move bin data to archive
		mv -v ${NewBinDataDir}/*.dat  ${ArchiveBinDir} 

	fi
fi 
# wait for MakeRawTree finished

#move previously selected data to archive
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: check ${QueueDataDir}"
if [ -z "$(ls -A ${QueueDataDir})" ]; then
   echo "Empty Queue data directory"
else

	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: move previous selected data to archive"
	#check number and size of files; size in kB
	ls -lh ${QueueDataDir}/*.root	#debug
	mv -v ${QueueDataDir}/*.root ${ArchiveSelDir}

	#v2: save HK to txt
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: move previous HK data to archive"
	mv -v ${QueueDataDir}/*.txt ${ArchiveHKDir}

fi

#get latest status update

#save intested printout for selected data
#ls : sort alphanumerically unless specified
#this will auto sort the rawStatus files as the name contains timestamp YYYYMMDD-hhmmss
#	rawStatus/status.0002F7F2DA83.20190115-145740.dat

#move previous generated status tree to archive
mv -v  ${NewStatusTreeDir}/*.root  ${ArchiveStatTreeDir}

#for debug: print out texts
LatestRawStatus="$( ls ${NewRawStatusDir}/status.${MbedMacAddress}.*.dat | tail -1 )"
##basename - strip directory and suffix from filenames;  -s remove a trailing suffix
# --> there is no -s option for basename at the BBB ........ wth
#LatestStatusTree="${NewStatusTreeDir}/$(basename -s .dat  ${LatestRawStatus}).root" 
#alternative ${string%substring}  Deletes shortest match of $substring from back of $string.
LatestRawStat=$(basename  ${LatestRawStatus})
LatestStatusTree="${NewStatusTreeDir}/${LatestRawStat%.*}.root" 

#create status tree for hourly HK summary
if [ -z "${LatestRawStatus}" ]; then
	echo "Latest raw status not available. skip"
else
	#debug
	python ${SnScriptOnlineDir}/readStatusPyRoot.py  ${LatestRawStatus} > ${LatestSSTHKTxt}
	#infile name, outfile name

	python ${SnScriptOnlineDir}/makeStatusTree.py  ${LatestRawStatus}  ${LatestStatusTree}
fi
#move rawStatus (.dat) files to archive;  is organizer available?
#only keep files in current DAQ window, just in case MBed time screws up
# ------> don't do this during threshold scan, as trigger rate is retrieved from latest rawStatus files
if [ $(cat ${IsTMScanTxt}) -eq 1 ]; then
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: ----- Threshold scan ongoing, Don't move rawStatus files"
else
	mv -v ${NewRawStatusDir}/status.${MbedMacAddress}.*.dat  ${ArchiveRawStatusDir} 
fi


#check raw data directory
if [ -z "$(ls -A ${NewRawDataDir})" ]; then
   echo "Empty Raw data directory. Skip event selection"
else
	#   echo "Not Empty"

	#	print "Usage: python doMakeCalTree.py [text file with inbasedir, "\
	#            "insubdir, calfile, fpnbasedir, outbasedir, badbasedir, "\
	#           "makeOneFpnPerDirectory]"

	#create text file with arguments; for configurable arguments (whether do ADC to voltage conversion)

	#FPN-subtracted only if calfile not specified
#	python ${MakeCalTreeMacro} ${NewRawDataDir} ${}

	#load latest event cut setting
	while read -r c1 c2
	do
	  echo "$c1 --> $c2"
	  if [ $c1 == "${EvtSelTitle}" ]; then
	  	LatestEvtSelInput=${c2}
	  	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: find latest selection cut at ${LatestEvtSelInput}"
	  fi
	  #if not found
	done < "${LatestDAQConfigTxt}"

	#executables or compiled with ROOT CINT 
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${EventSelectMacro}"
	#Int_t TarogeMEventSelection(const Char_t* const fname_evt, const Char_t* const fname_stat=NULL, const Char_t* const fname_cut=kDefEvtFilterConfName);
	#default cut values are loaded first, then user-defined one, in case the latter is not complete
	#if user-defined is not found, default one is used
	#export DefEventSelectInput="${EventSelectDir}/DefaultEventSelectCut.txt"
	# -b: batch  -l: no splash screen  -q exit after processing

	#root -b -l -q "${EventSelectMacro}+( \"${NewRawDataList}\", \"${LatestStatusTree}\", \"${EventSelectInput}\")"
	root -b -l -q "${EventSelectMacro}+( \"${NewRawDataList}\", \"${LatestStatusTree}\", \"${LatestEvtSelInput}\")"
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${EventSelectMacro}"
fi

#check selected data
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: check ${QueueDataDir}"
if [ -z "$(ls -A ${QueueDataDir})" ]; then
   echo "Empty Queue data directory. No selected data was generated"
else

	#check number and size of files; size in kB
	du -l ${QueueDataDir}/*.root

	if [ "$(du -l ${QueueDataDir}/*.root | wc -l)" -gt 1 ]; then

		echo "Warning: more than 1 file in ${QueueDataDir}"
	fi


	#move raw  dta tree files to archive; 
	#only keep files in current DAQ window, just in case MBed time screws up
	#export NewRawDataDir="${TarogeMDir}/new_raw_data"
	#export ArchiveRawDir="${ArchiveDir}/raw"
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: move raw trees to archive ${ArchiveRawDir}"
	mv -v ${NewRawDataDir}/*  ${ArchiveRawDir} 

fi

echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"
