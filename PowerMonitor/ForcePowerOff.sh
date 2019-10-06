#CHC
#S.H. Wang 2017
#20170518: add relay #12: external HDD
#S.Y. Hsu 2018 TAROGE-3
#20180705: Updating the command to the Arduino for TAROGE-3 PowerController code.

#bash and sh are two different shells. Basically bash is sh, with more features and better syntax
#!/bin/bash

####
#UserDir="/home/taroge/"
####

#source is a Bash built-in function
#source ${ScriptHKSetting}
. ${TarogeHKSetupMacro}
#ScriptHKSetting="${UserDir}PowerMonitor/LoadHKSetting.sh"
ScriptPMKill="${PowControlDir}/PMKill.sh"

. ${ScriptPMKill}


ArduinoFound=0
NoArduinoWarning=0

#if IDN text is not empty, confirm it's arduino
#if not, find the device

#try if there's record in txt; if found, no need to process FindDevice
#if [ -s ${ArduinoIDNTxt} ]; then

TTYPORT=$( cat ${ArduinoIDNTxt} )
IDN=$(${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -s "?IDN" -r)
sleep 2
echo "(PowerOff) check previous address at ${TTYPORT}  ?IDN: ${IDN}" >> $PowControlLog

if [ ${IDN}=${ArduinoIDN} ]; then

	ArduinoFound=1
else
	#current address is invalid, reset (it's fine because this is the last script)
	echo "(Poweroff) Arduino is found in previous address: ${TTYPORT} ${IDN}" >> $PowControlLog
	echo "" > ${ArduinoIDNTxt}

	TTYPORT=""

	#FindDevice should gurantee Arduino is found before return
	source ${ScriptFindDevice}
	ArduinoFound=$?

	TTYPORT=$( cat ${ArduinoIDNTxt} )
	IDN=$(${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -s "?IDN" -r)
	sleep 2	
fi

#fi


echo "(PowerOff) Arduino is found at: ${TTYPORT} ${IDN}" >> $PowControlLog

#to directory containing DAQ interrupt text
#cd ${ExeDir}
#cd /home/taroge/arduino-serialTAROGE/
cd ${PowControlDir}



#Shutdown procedure
source ${ScriptPowerOffMail} #Sending the mail.
echo "(PowerOff) $(date '+%0Y/%0m/%0d %0H:%0M:%0S') Houston, We've Got a Problem " >> ${PowControlLog}	#ShutdownRecord.txt

echo "(PowerOff) Turning off DAQ" >> ${PowControlLog}	#ShutdownRecord.txt


#prevent runTaroge2.sh call ps6000conT3 
echo "0" > ${PowerReadyTxt}

#echo "0" > ${DAQInterruptTxt}	#Taroge-3: LoadHKSetting.sh
echo "0" > ${DAQStateTxt}	#Taroge-4: env var

sleep 10

echo "(PowerOff) Turning off the relay of devices"  >> ${PowControlLog}
${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 1000 -s "RELAYS ALLOFF 1" -r >> ${PowControlLog}
#./arduino-serial -b 9600 -q -p $TTYPORT -t 1000 -s "RELAY 10000000000 0" -r >> ShutdownRecord.txt
sleep 10

echo "(PowerOff) $(date '+%0Y/%0m/%0d %0H:%0M:%0S') Turning off the PC" >> ${PowControlLog}

#command only for switching off PC relay (others are ignored)
${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 1000 -s "PCRELAYOFF 60" -r >> ${PowControlLog}

#echo "(PowerOff) ${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -t 1000 -s \"RELAY 00000000000 60\" -r" >> ${PowControlLog}

#./arduino-serial -b 9600 -q -p $TTYPORT -t 1000 -s "RELAY 00000000000 60" -r  >> ShutdownRecord.txt


sleep 5
#should be in ROOT
echo "(PowerOff) sudo shutdown -P now" >> ${PowControlLog}
#require editing visudo to run sudo without entering password
sudo shutdown -P now >> ${PowControlLog}
