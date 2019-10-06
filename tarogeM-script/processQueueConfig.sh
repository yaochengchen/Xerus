#!/bin/bash
#processQueueConfig.sh for TAROGE-Melbourne
#S.H. Wang 2019-02
#
#The script should be run right after (probably scheduled by crontab) Inmarsat communication, check if there's new scan request and config coming at queue_config/ folder
#
# the text files for threshold scan request should have timestamp as filename for sorting, e.g. Scan-20190217080748.txt
# SST config file should be a text file with name  appended by run number, e.g. TarogeM-xxxxx-000201.txt
#
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"
TimeString=$( date -u '+%Y%0m%0d-%H%0M%0S')  


#station const
#in case global constants are not loaded
.  ${TarogeMDir}/TarogeMIOConstant.sh

#check if there is request to terminate currently running scan (due to long waiting time, stuck. etc.)
#retrieve the unfinished report
ls ${QueueScanDir}/${ScanTitle}*.txt
LatestScanSetup="$( ls ${QueueScanDir}/${ScanTitle}*.txt | tail -1 )"

if [ -f  "${LatestScanSetup}" ]; then
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: check if there's request for stopping scans"
	while read -r c1 c2
	do
	  echo "$c1 --> $c2"
	  #should be consistent with TarogeM-autoSetThermalThresholdFastFromText.py
	  if [ $c1 == "restart"  ]; then
		#statements
		pid_scan=$(ps -ef | grep -v "grep" | grep "${ThreshScanMacro}" | awk '{print $2}')
		echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC : find pid of scan script ${ThreshScanMacro} --> kill ${pid_scan}"
		#kill will terminate python process and IsTMScan.txt will reset to 0
		if [ ! -z "${pid_scan}" ];then
			kill  ${pid_scan}		

			echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :waiting 60 sec for previous ${0} to finish"
			##if python script for scan is killed, but the previous script is still running
			sleep 60	  	
		fi
	  fi
	done < "${LatestScanSetup}"
fi


#check if previous script is running
#from stackoverflow
for pid in $(pidof -x ${0}); do
	#exclude the current script
    if [ ${pid} != $$ ]; then
    	#man bash: $$ Expands to the process ID of the shell. In a () subshell, it expands to the process ID of the current shell, not the subshell.
        echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :${0} : Process is already running with PID ${pid}.  skip this run."
        exit 1
    fi
done


# move previous scan report to archive
# the report for running scan is saved at archive scan dir, so no worry for moving the contents away
echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :move queue report to archive"
mv -v ${QueueReportDir}/*.txt  ${ArchiveReportDir}

#check if trigger threshold scan, which submit multiple config to SST,  is requested before checking new config

#for configfile in ${QueueConfigDir}/*.txt; do
#only process the last request, skip earlier ones
#only file with 'scan' prefix, sorting according to timestamp at the file name
#filelist=$(find ${QueueScanDir} -type f -name "${ScanTitle}*.txt" | sort -g)
#ls -A

if [ -z  "${LatestScanSetup}" ]; then
#if [ -z "${filelist}" ]; then
   echo "No threshold scan request."
else

#	for scanfile in ${filelist} ; do
#		echo "${scanfile} "
#	done

    #export ThreshScanMacro="${SnScriptOnlineDir}/TarogeM-autoSetThermalThreshold.py"
    #sort:  -g, --general-numeric-sort     compare according to general numerical value
        #$(find ${QueueScanDir} -type f -name "*.txt" | sort -g | tail -n1)
    #ls : sort alphanumerically unless specified
    #LatestScanSetup="$( ls ${QueueScanDir}/${ScanTitle}*.txt | tail -1 )"
    
    echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: get Latest scan setup ${LatestScanSetup}"
    
	#LatestScanSetup="${ArchiveScanDir}/$(basename $( ls ${QueueScanDir}/${ScanTitle}*.txt | tail -1 ) )"	
	#move scan request file to archive first, in case the scan is hanging and repeat after get killed
	#export ArchiveScanDir="${ArchiveDir}/scan"
	mv -v  ${QueueScanDir}/${ScanTitle}*.txt   ${ArchiveScanDir}
	LatestScanSetup="${ArchiveScanDir}/$(basename ${LatestScanSetup})"


    #this may take several hours....
    #the data-taking window of SST is set to min (60 or 120 sec), and communicate freqquently with BBB, and no event is saved during scan.
    #Therefore it should be safe to run processTarogeMData.sh by crontab in parallel
    #How to run with default setting?
    #output saved in ArchiveReportDir

    #to block processTarogeMData move binary data
    echo "1" > ${IsTMScanTxt}
    echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: IsTMScan: $(cat ${IsTMScanTxt}) --->  run trigger threshold scan: python ${ThreshScanMacro}  ${LatestScanSetup}"
	python ${ThreshScanMacro}  ${LatestScanSetup}

	echo "0" > ${IsTMScanTxt}
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: IsTMScan: $(cat ${IsTMScanTxt}) ---> trigger threshold scan done"


	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: update Scan report in ${LatestDAQConfig}"
	while read -r c1 c2
	do
	  echo "$c1 --> $c2"
	  #should be consistent with TarogeM-autoSetThermalThresholdFastFromText.py
	  if [ $c1 == "outtxt" ]; then
	  	LastestScanReport=${ArchiveReportDir}/${c2}
	  	
	  fi
	done < "${LatestScanSetup}"

	#submit the report to queue if exists 
	if [ -f ${LastestScanReport} ]; then
		echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: find latest scan report at ${LastestScanReport}"
		sed -i "s:^${ScanTitle}.*:${ScanTitle}\t${LastestScanReport}:g" ${LatestDAQConfigTxt}
	
		#thermal_thresholds_station913_20190118-1309.json
		#sorted timestamp in file name 
		#LastestScanReport=$( ls  ${ArchiveReportDir}/thermal_thresholds_fast_station913_*.json | tail -1)
		echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: Queue latest scan report: ${LastestScanReport}"
		cp -v ${LastestScanReport}  ${QueueReportDir}

	else
		echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: scan report ${LastestScanReport} not exist"
	fi

	#send new config to SST with new thresholds

	#alternative: auto set to high threshold config, waiting user for sending new config
	#default
	python ${SnScriptOnlineDir}/addConfToQueue.py   ${DefSSTConfig}   ${MbedMacAddress}
fi

# --------- process new SST config only after threshold scan is complete 
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: check SST config in ${QueueConfigDir}"

#
#it's possible SST Comm window is always overlapped with addConfToQueue
#if [ "$(cat ${IsSSTCommTxt})" -eq 1 ]; then
#	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC:  IsSSTCommTxt=1  skip processing Binary data files"
#else
#sort by run number
filelist=$(find ${QueueConfigDir} -type f -name "${ConfigTitle}*.txt" | sort -V)
#if [ -z "$(ls -A ${QueueConfigDir})" ]; then
if [ -z "${filelist}" ]; then
   #echo "Empty Queue Config directory. Run with current config..."
   echo "No new config for Taroge-M. Run with current config..."
else
	#list of config files in folder, sortied by run number
	#find:   -type f : only files (skip directories);  -name "RawTree*.root" for name pattern
	#export QueueConfigDir="${TarogeMDir}/queue_config"
	#find ${QueueConfigDir} -type f -name "${ConfigTitle}*.txt"
	#filelist=$(find ${QueueConfigDir} -type f -name "${ConfigTitle}*.txt" | sort -V)
	for configfile in ${filelist} ; do
	    echo "python ${SnScriptOnlineDir}/addConfToQueue.py   ${configfile}   ${MbedMacAddress}"
	    #protector for incomplete input

	    #put config into queue  
		python ${SnScriptOnlineDir}/addConfToQueue.py   ${configfile}   ${MbedMacAddress}
	done

	#
	configfile=$( basename ${configfile})
		
	#move config file to archive
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: move queue config to archive"
	mv -v  ${QueueConfigDir}/${ConfigTitle}*.txt   ${ArchiveConfigDir}

	#update latest DAQ config text;
	LatestSSTConfig=${ArchiveConfigDir}/${configfile}
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: update latest SST config: ${LatestSSTConfig} in ${LatestSSTConfig}"
	sed -i "s:^${ConfigTitle}.*:${ConfigTitle}\t${LatestSSTConfig}:g" ${LatestDAQConfigTxt}

	#move binary files, too
	mv -v  ${QueueConfigDir}/${ConfigTitle}*.dat   ${ArchiveConfigDir}
fi

#writting to AriStage file is over (addConfToQueue.py)
#if AriStage.*.root get locked, unlock it by move .root.lock away (why is it not unlocked autoly?)
#asynchronous file AriStage.*.root may get locked if reading and writing at the same time
AriStageLock="${SnStageDir}/AriStage.${MbedMacAddress}.root.lock"
if [ -f ${AriStageLock} ] ; then
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: move file lock away: ${AriStageLock}"
	mv -v ${AriStageLock}  ${SnStageDir}/bad
fi

#if AriStage get locked, printStationActors.py will not work
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC:  python ${SnScriptOnlineDir}/printStationActors.py   ${MbedMacAddress}"
#make sure all config are processed and queued
python ${SnScriptOnlineDir}/printStationActors.py   ${MbedMacAddress}



echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: check Event selection setting in ${QueueConfigDir}"

#filelist=$(find ${QueueConfigDir} -type f -name "${EvtSelTitle}*.txt" | sort -V)
	#if there are multiple files, choose the latest one
ls -l ${QueueConfigDir}/${EvtSelTitle}*.txt
LatestEvtSel="$( ls ${QueueConfigDir}/${EvtSelTitle}*.txt | tail -1 )"
#if [ -z "$(ls -A ${QueueConfigDir})" ]; then
if [ -z "${LatestEvtSel}" ]; then
   #echo "Empty Queue Config directory. Run with current config..."
   echo "No new event selection cut for Taroge-M. Run with current settings..."
else
	baseEvtSel=$(basename ${LatestEvtSel})
	#move config file to archive
	#export ArchiveSelCutDir="${ArchiveDir}/selcut"
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: move queue config to archive"
	mv -v  ${QueueConfigDir}/${EvtSelTitle}*.txt   ${ArchiveSelCutDir}

	#export LatestDAQConfigTxt="${EventSelectDir}/LatestDAQConfig.txt"
	#replace line of SST config 
	#/c\ Replace the selected lines with text,
	#since variables contain slash, use semicolon as delimiter for sed
	#line starting with keyword and replace whole line
	LatestEvtSel=${ArchiveSelCutDir}/${baseEvtSel}
	echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: update latest selection cut in ${LatestDAQConfigTxt}"
	sed -i "s:^${EvtSelTitle}.*:${EvtSelTitle}\t${LatestEvtSel}:g" ${LatestDAQConfigTxt}

fi


echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"

