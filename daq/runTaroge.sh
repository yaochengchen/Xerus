#!/bin/sh

#sleep 120
#initial value of scan
Threshold0=600

#test: when power is ready
LogPowerReady="${TarogeDAQDir}/log_power_ready.txt"

#text file recording starting threshold from threshold scan
StartThreshTxt="${TarogeTrigDir}/get_start_step.txt"
#Taroge-4
#TarogeIOConstant.sh
#	TarogeDAQExe="${TarogeDAQDir}/ps6000conT4"
#SourceDir="/home/taroge/source/"
#TarogeDAQDir="${TarogeDir}/daq"

#Taroge-3
#TarogeDAQDir="${SourceDir}taroge2/"
#TarogeDAQExe="ps6000conT3"
#PowerReadyTxt="${TarogeDAQDir}/PowerReady.txt"


#to avoid DAQ start before relays are on
#contain 1 if power is ready 
while [ 1 ]
do

	#PowerReadyTxt control by PowerMonitor.sh
	PowerReady=`cat ${PowerReadyTxt}`
#	echo ${PowerReady}

	if [ "${PowerReady}" -eq 1 ];
	then
		echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Power is ready. Start threshold scan and DAQ..." >> ${LogPowerReady} &		
		break
	fi

#	echo "power is not ready..."

	sleep 5
	
done


#trigger threshold scan
# to trigger folder ${TarogeTrigDir}="${TarogeDir}/trigger"

#cd ${SourceDir}taroge2_trigger_soft/
#sh labrun_t2.sh
# . is more universal than sh
cd ${TarogeTrigDir}
. ${TarogeThreshScanMacro}
#ls


cd ${TarogeDAQDir}


# ${Threshold0} should be updated by 
Threshold0=$(cat ${StartThreshTxt})

#give initial trigger threshold to DAQ program
${TarogeDAQExe} ${Threshold0} &> ${TarogeDAQDir}/log.txt &


while [ 1 ]
do
 	#Taroge-M
 	#check if previous script is running
	#from stackoverflow
	#pidof -- find the process ID of a running program.
	#-x     Scripts too - this causes the program to also return process id's of  shells  running  the    named scripts.
	#for pid in $(pidof -x ${TarogeDAQExe} ); do
	#	#exclude the current script
	#    if [ ${pid} != $$ ]; then
	#    	#man bash: $$ Expands to the process ID of the shell. In a () subshell, it expands to the process #ID of the current shell, not the subshell.
	#        echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :${TarogeDAQExe} : Process is already running with PID ${pid} #. skip this run."
	#        exit 1
	#    fi
	#done



    #CHC: check if DAQ is alive
    process=$(ps x |grep -v grep |grep -c "${TarogeDAQExe}" );  #"ps6000conCHC3"

    #echo $process

    if [ ${process} = 0 ]; 
    then 
			sleep 10

			PowerReady=`cat ${PowerReadyTxt}`
			#echo ${PowerReady}
			if [ "${PowerReady}" -eq 1 ];
			then
				echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Power is ready. Restart DAQ..." >> ${LogPowerReady} &				
				${TarogeDAQExe} ${Threshold0} &> ${TarogeDAQDir}/log.txt &
			fi


    fi
 

    sleep 60 #CHC: wait for 60 seconds 

done
