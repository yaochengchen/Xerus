#!/bin/bash

#S.Y. Hsu 2018/07/08

#UserDir="/home/taroge/"
#ScriptHKSetting="${UserDir}PowerMonitor/LoadHKSetting.sh"
#source is a Bash built-in function
#source ${ScriptHKSetting}
. ${TarogeHKSetupMacro}

#NAME_PM="${PowControlDir}PowerMonitor.sh"
NAME_PM=${TarogePowMonMacro}
	#"${PowControlDir}PowerMonitor.sh"

# NAME_PM="${PowControlDir}/SYTest.sh" 

NAME_PIDFILE="${PowControlDir}/PID.txt"
NAME_PIDCHECK="${PowControlDir}/PIDCheck"
#ps -elf | grep ${NAME_PM}

echo -e "\n" '(PMFind.sh)' >> ${PowControlLog}


#echo "Searing for the PID of the process including ${NAME_PM} ..."
ps -elf | grep "${NAME_PM}" | awk '{print $4}' > ${NAME_PIDFILE}
ps -elf | grep "${NAME_PM}" | awk '{print $4}' >> ${NAME_PIDFILE}
ps -elf | grep "${NAME_PM}" | awk '{print $4}' >> ${NAME_PIDFILE}


PID=$(${NAME_PIDCHECK})
if [ "${PID}" = 0 ]; then
	echo "0" > ${NAME_PIDFILE}
else
	echo "${PID}" > ${NAME_PIDFILE}
fi

echo -e '(PMFind.sh)'"\n" >> ${PowControlLog}

