#!/bin/bash

#S.Y. Hsu 2018/07/08

# naming convention for folder: 
#	TAROGE-3:  no trailing "/" 
#	TAROGE-4: with trailing "/" for clarity

#UserDir="/home/taroge/"
#ScriptHKSetting="${UserDir}PowerMonitor/LoadHKSetting.sh"
#source is a Bash built-in function
#source ${ScriptHKSetting}
. ${TarogeHKSetupMacro}

NAME_PM="${PowControlDir}/PowerMonitor.sh"
NAME_PIDFILE="${PowControlDir}/PID.txt"
NAME_PIDCHECK="${PowControlDir}/PIDCheck"

echo -e "\n"'(PMKill.sh)' >> ${PowControlLog}


read -p "This script will kill the PowerMonitor, are you sure? (y/n)" CERT
echo ${CERT}


if [ ${CERT} = "y" ]; then
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Preparing to kill the PowerMonitor. Please resume the PowerMonitor in 30 minutes."
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Preparing to kill the PowerMonitor. Please resume the PowerMonitor in 30 minutes." >> ${PowControlLog}
	sleep 3

	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Trying to find the PID of the PowerMonitor..."
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Trying to find the PID of the PowerMonitor..." >> ${PowControlLog}
	${PowControlDir}/PMFind.sh
	PID=$(cat ${NAME_PIDFILE})
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "PID=${PID}"


	if [ ${PID} = "0" ]; then
		echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Cannot find the PID of the PowerMonitor.sh. Maybe it is not running?"
		echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Cannot find the PID of the PowerMonitor.sh. Maybe it is not running?" >> ${PowControlLog}
	else
		while [ ${PID} != "0" ]
		do
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Killing the PID of the PowerMinotor ${PID} ..."
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Killing the PID of the PowerMinotor ${PID} ..." >> ${PowControlLog}
			kill ${PID}
			####Sometimes there are 2 PIDs needed to be killed.
			${PowControlDir}/PMFind.sh
			PID=$(cat ${NAME_PIDFILE})
		done
	fi
	#echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "PID = ${PID}" >> ${PowControlLog}
	#rm ${NAME_PIDFILE}
else
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Cancelled"
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Cancelled" >> ${PowControlLog}
fi

echo -e '(PMKill.sh)' "\n" >> ${PowControlLog}

