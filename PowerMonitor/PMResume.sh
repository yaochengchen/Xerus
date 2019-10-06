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

NAME_PM=${TarogePowMonMacro}
	#"${PowControlDir}/PowerMonitor.sh"
NAME_PIDFILE="${PowControlDir}/PID.txt"
NAME_PIDCHECK="${PowControlDir}/PIDCheck"

echo -e "\n" '(PMResumed.sh)' >> ${PowControlLog}


echo "Preparing to resume the PowerMonitor."
echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Preparing to kill the PowerMonitor...Please remember to resume the PowerMonitor in 30 minutes." >> ${PowControlLog}
sleep 1

echo "Check if the PowerMonitor is already running..."
echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Check if the PowerMonitor is already running..." >> ${PowControlLog}

${PowControlDir}/PMFind.sh
PID=$(cat ${NAME_PIDFILE})
rm ${NAME_PIDFILE}

if [ ${PID} = "0" ]; then
	echo "Resume the PowerMonitor"
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Trying to find the PID of the PowerMonitor. Resume the PowerMonitor" >> ${PowControlLog}
	${NAME_PM} &
else
	echo "The PowerMonitor.sh is already running!, PID = ${PID} ."
	echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Killing the PowerMinotor..." >> ${PowControlLog}
fi


echo -e '(PMResumed.sh)'"\n" >> ${PowControlLog}



