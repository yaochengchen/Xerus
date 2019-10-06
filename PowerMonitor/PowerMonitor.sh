#!/bin/bash

########
# Power Monitor Code for TAROGE-3
########

#User Directory
#UserDir="/home/taroge/"
#ScriptHKSetting="${UserDir}PowerMonitor/LoadHKSetting.sh"
#source is a Bash built-in function
#source ${ScriptHKSetting}

# echo "Go into PM" > "/home/taroge4/PM.log"
# echo "HKSetupPath: ${TarogeHKSetupMacro}" >> "/home/taroge4/PM.log"
. ${TarogeHKSetupMacro}

printf "\n\n(PowerMonitor) Script Started...." >> $PowControlLog
#/bin/date >> $PowControlLog

date '+%Y/%0m/%0d %0H:%0M:%0S' >>  $PowControlLog

#load variables
printf "(PowerMonitor) loading variables...." >> $PowControlLog


#tty port
IDN=""

#FindDevice should guarantee Arduino is found before return
. ${ScriptFindDevice}

#check return value
ArduinoFound=$?
NoArduinoWarning=0
#echo "return value: $ArduinoFound  $TTYPORT"


#device is found and the text is not empty
#if [ ${ArduinoFound} = 1 ] && [ -s ${ArduinoIDNTxt} ]; then

TTYPORT=$( cat ${ArduinoIDNTxt} )
IDN=$(${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -s "?IDN" -r)
sleep 1

#echo "${ArduinoFound} Sending commands to ${TTYPORT}  ?IDN: ${IDN}"

#fi

echo "${ArduinoFound} Sending commands to ${TTYPORT}  ?IDN: ${IDN}" >> $PowControlLog
#echo "test3" >> logPower.txt


#swith on relays one by one
#for i in $(seq 1 $(($NumRelay-1)) )
#do
#	#first relay (PC) is always on
#	RelayStateString=""
#	for j in $(seq 1 $(($NumRelay-1)) )
#	do
#		#echo "$i $j"
#		if [ $j -le $i ]; then
#			RelayStateString="${RelayStateString}1"
#		else
#			RelayStateString="${RelayStateString}0"
#		fi
#	done
#	
#
#	echo "RELAYS ${RelayStateString}" >> $PowControlLog
#
#	${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 1000 -s "RELAYS ${RelayStateString} 1 " -r >> $PowControlLog
#
#
#done

#swith on relays
#echo "RELAYS 0000000000000 1" >> $PowControlLog
#${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "RELAYS 00000000000000 1 " -r >> $PowControlLog
#sleep 2


echo "0" > ${PowerReadyTxt}

echo "RELAYS ALLON 1" >> $PowControlLog
${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "RELAYS ALLON 1" -r >> $PowControlLog
# ${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "RELAY OSC 1" -r >> $PowControlLog

sleep 10

#Set the VLevel (for test)
#echo "VLEVEL BOOTUP 26.4" >> $PowControlLog
#${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "VLEVEL BOOTUP 26.4" -r >> $PowControlLog
#sleep 1
#echo "VLEVEL SHUTDOWN 23.0" >> $PowControlLog
#${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "VLEVEL SHUTDOWN 23.0" -r >> $PowControlLog
#sleep 1
#echo "VLEVEL DANGER 21.6" >> $PowControlLog
#${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "VLEVEL DANGER 21.6" -r >> $PowControlLog
#sleep 1

#Set the Alarm (for test)
#echo "ALARM LOSTPC 50" >> $PowControlLog
#${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "ALARM LOSTPC 50" -r >> $PowControlLog
#sleep 1

#Set ?IDN (for test)
# ${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "?IDN" -r >> $PowControlLog
# sleep 1

WARNING=0
OverheatCounter=0
LowDiskCounter=0
LowDiskWarning=0
FailMPPTCounter=0
FailMPPTWarning=0

#${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p $TTYPORT -t 30000 -s "?HK" -r > HousekeepingData.txt
#./combineHK
echo "Reading HK data..." >> $PowControlLog

#CHC: change to combineHK, to add in time information together. save to hkSummaryYYYYMMDD.txt
#it will save to different files everyday

#${UserDir}source/taroge2/ps6000conT3 &> ${UserDir}source/taroge2/log.txt & 

#tell DAQ power is ready
echo "1" > ${PowerReadyTxt}


while [ 1 ]
do

	#get date and find/create HK file
	HKFileName="${HKFilePrefix}$(date '+%0Y%0m%0d')${HKFileExt}" 


	#PC HK
	#-date and time
	#-CPU temperature
	#--awk: find the interested column;  sed: remove unwanted characters
	#-disk space in KB
	#--system: /dev/sda1 460G
	#--device total used available

	DiskSpace_KB=$(df | grep '/dev/sda1' | awk '{print $4}')
	# $(sensors | grep 'Core ' | awk '{print $3}' |  sed 's/°C//g')
	TempCore0=$( sensors | grep 'Core 0' | awk '{print $3}' |  sed 's/°C//g' |  sed 's/+//g')
	TempCore1=$( sensors | grep 'Core 1' | awk '{print $3}' |  sed 's/°C//g' |  sed 's/+//g' )

	PCHKDataString=$( printf "%4d %02d %02d %02d %02d %02d %d %.1f %.1f %d" $(date '+%Y %-m %-d %-H %-M %-S %s') ${TempCore0} ${TempCore1} ${DiskSpace_KB}  )
	
	#MPPT HK
    HKDataString=$(${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p $TTYPORT -t 30000 -s "?HK" -r) 

	#echo "${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p $TTYPORT -t 30000 -s "?HK" -r"
	#echo $PCHKDataString
	#echo $HKDataString

	echo "$PCHKDataString $HKDataString" >> $HKFileName


	#Handle low disk space: send warning via mail, interrupt DAQ code, switch off all other relays
	if [ ${DiskSpace_KB} -lt ${DiskSpaceLow_KB} ]; then
		#because PC will keep taking HK data, LowDiskWarning is used to prevent repeated warning
		if [ "${LowDiskWarning}" = 0 ]; then
			LowDiskCounter=$((${LowDiskCounter} + 1))
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: low disk space: ${DiskSpace_KB} < ${DiskSpaceLow_KB}: ${LowDiskCounter}" >> $PowControlLog
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: low disk space: ${DiskSpace_KB} < ${DiskSpaceLow_KB}: ${LowDiskCounter}" >> ${SysWarningMessageTxt}
			#error handling
			if [ "${LowDiskCounter}" -ge "${MaxNumLowDisk}" ]; then
				#send mail
				echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Truning off the DAQ due to the low disk space." >> ${PowControlLog}
				echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Truning off the DAQ due to the low disk space." >> ${SysWarningMessageTxt}

				#interrupt DAQ
				#DAQ program should be restarted manually
				#------------ PowerMonitor.sh should be interrupt and restart manuall -------------
				
				
				echo "Turning off DAQ..." >> ${PowControlLog}	 	#ShutdownRecord.txt
				###cp ${DAQInterruptTxt0} ${DAQInterruptTxt}
				echo "0" > ${PowerReadyTxt}
				# echo "0" > ${DAQInterruptTxt}
				echo "0" > ${DAQStateTxt}
				sleep 10

				#switch off DAQ-related relays: Scopes, LNAs, Trigger Board, Oscillator
				echo "Turning off the relay of devices"  >> ${PowControlLog}	#ShutdownRecord.txt
				# ${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 2000 -s "RELAYS 00000011101101 1" -r >> ${PowControlLog}
				${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 2000 -s "RELAYS 00000011001011 1" -r >> ${PowControlLog}


				sleep 5
				#stay on and online for data transfer; require manually restart DAQ then
				#to prevent repeated warning
				echo "(LowDiskSpace) Waiting for data transfer. Taking HK data only..." >> ${PowControlLog}
				LowDiskWarning=1
			fi
		fi
	else
		#with enough disk space or warning=1
		LowDiskCounter=0
		if [ "${LowDiskWarning}" = 1 ]; then
			echo "(LowDiskSpace) Warning is lifted... Please restart the DAQ manually" >> ${PowControlLog}
			LowDiskWarning=0
		fi

	fi

	#Handle overheat: send warning via mail, Power off all relays, forced arduino to wait
	#temperature has +/- sign in front (string)

	#printf "test:   %.1f  %.1f vs %.1f \n" ${TempCore0} ${TempCore1} ${TempOverheat}
	#tch=$( echo "${TempCore0} >= ${TempOverheat}" | bc )
	#echo "check $tch"

	#compare temperature (floating-point)
	if [ $( echo "${TempCore0} >= ${TempOverheat}" | bc ) = 1 ] && [ $( echo "${TempCore1} >=${TempOverheat}" | bc ) = 1 ]; then

		OverheatCounter=$((${OverheatCounter} + 1))
		echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: CPU Overheated: ${TempCore0} ${TempCore1} > ${TempOverheat}: ${OverheatCounter}" >> $PowControlLog
		echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: CPU Overheated: ${TempCore0} ${TempCore1} > ${TempOverheat}: ${OverheatCounter}" >> ${SysWarningMessageTxt}

		#error handling
		if [ "${OverheatCounter}" -ge "${MaxNumOverheat}" ]; then
			#send mail
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Shutdown due to the overheat. " >> $PowControlLog
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Shutdown due to the overheat. " >> ${SysWarningMessageTxt}
			
			#run PowerOff.sh but in addition
			#force Arduino to wait for PC cooldown; start countdown after PC relay is off
			${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 3000 -s "SLEEP ${ArduinoWaitCount}" -r >> $PowControlLog
			sleep 3
			break
		fi
	else
		OverheatCounter=0
	fi


	#check if get HK data from arduino
	#no HK data:  1. PC<->Arduino (try FindDevice)  
	#if Arduino<->MPPT is lost, there are still DHT22 sensor and nonsense string
	if [ -z "${HKDataString}" ]; then

		echo "$(date '+%Y/%0m/%0d %0H:%0M:%0S') no HK data string. seems lost Arduino... " >> $PowControlLog
		#FindDevice should guarantee Arduino is found before return
		. ${ScriptFindDevice} 1
		#check return value
		ArduinoFound=$?

		
		TTYPORT=$( cat ${ArduinoIDNTxt} )
		IDN=$(${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -s "?IDN" -r)
		sleep 3

		echo "${ArduinoFound} Reconnect to ${TTYPORT}  ?IDN: ${IDN}" >> $PowControlLog

	else
		#check if MPPT<->arduino has good connection
		#MPPT warning is the 2nd entry of HK data; = null if no HK data return so should be safe
		#all MPPT HK data should become -1
		WarningString=$(echo "$HKDataString" | awk '{print $2}')
		if [ "$WarningString" = 1 ]; then
			
			FailMPPTCounter=$((${FailMPPTCounter} + 1))
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: The Power Board lost the MPPT controller: ${FailMPPTCounter}" >> $PowControlLog
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: The Power Board lost the MPPT controller: ${FailMPPTCounter}" >> ${SysWarningMessageTxt}

			if [ "${FailMPPTCounter}" -ge "${MaxNumFailMPPT}" ]; then
				echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Forced-Shutdown dut to lose the MPPT for more than ${MaxNumFailMPPT} times in serial. " >> $PowControlLog				
				echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Forced-Shutdown dut to lose the MPPT for more than ${MaxNumFailMPPT} times in serial. " >> ${SysWarningMessageTxt}				
				break
			fi
		else
			FailMPPTCounter=0
		fi


		#Shutdown/Wakep warning is the 1st entry of HK data; =null if no HK data return so should be safe
		WarningString=$(echo "$HKDataString" | awk '{print $1}')
		if [ "$WarningString" = 1 ]; then
			LowBATCounter=$(($LowBATCounter + 1))	
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "The battery voltage is lower than the shutdown level: ${LowBATCounter}" >> $PowControlLog
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "The battery voltage is lower than the shutdown level: ${LowBATCounter}" >> ${SysWarningMessageTxt}

			if [ "$LowBATCounter" -ge "${Num_ShutPC}" ]; then
				echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Battery voltage lower than shutdown voltage. System is going to power off" >> $PowControlLog		
				echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "Warning: Battery voltage lower than shutdown voltage. System is going to power off" >> ${SysWarningMessageTxt}
				break
			fi
		else
			LowBATCounter=0
		fi
	fi
    #CHC: check if DAQ is alive
    #process=$(ps x |grep -v grep |grep -c "ps6000conT3");
    #if [ $process -ne 2 ]; 
    #then 
	#${UserDir}source/taroge2/ps6000conT3 >&${UserDir}source/taroge2/log.txt 
    #fi

    sleep ${PeriodHKTaking} # wait for xx seconds 

done

#Turn on DAQ (CHC)
#we need to decide the condition to turn on DAQ code
#${UserDir}source/taroge2/ps6000conT3 &

sleep 1

echo "Call ${ScriptPowerOff}">> $PowControlLog

#disable it for test
. ${ScriptPowerOff} 





