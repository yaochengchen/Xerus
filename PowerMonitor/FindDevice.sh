
#!/bin/sh

#ScriptHKSetting="${UserDir}PowerMonitor/LoadHKSetting.sh"

FindDevice(){

	#load variables
	#printf "(FindDevice) loading variables...." 	#>> $PowControlLog
	#source ${ScriptHKSetting}

	. ${TarogeHKSetupMacro}


	# echo "cd ${PowControlDir}" >> $PowControlLog
	cd ${PowControlDir}

	#CHC: search arduino for 3 times
	#multiple trial because sometimes it fails even adruino is connected

	#tty port
	ArduinoFound=0 
	ACMNUM=0
	IDN=""
	FindCounter=0
	NoArduinoWarning=0

	searchACM=0

	# if [ $(($1)) = 1 ]; then
	# 	NoArduinoWarning=1
	# fi

	# echo "(FindDevice) Here" >> $PowControlLog
	echo "(FindDevice) Looking for ${ArduinoDevPrefix}"  >> $PowControlLog

while [ ${ArduinoFound} = 0 ]
do
	FindCounter=$((${FindCounter}+1))

	while [ $searchACM -lt 3 ]
	do
	    echo "(FindDevice) loop: ${FindCounter} trial: ${searchACM}" >> $PowControlLog

	    for ACMNUM in `seq 0 10`

	    do

		# choose the correct prefix
		TTYPORT="${ArduinoDevPrefix}${ACMNUM}"

		#-b: baud rate; -q: quiet ; -t:  Timeout for reads in millisecs (default 5000): -s: send; -r: receive
		#./arduino-serial -b 9600 -q -p $TTYPORT -s "?IDN" -r > IDNRead.txt
		IDN=$(${ArduinoSerialCmd} -b ${ArduinoBaudRate} -q -p ${TTYPORT} -s "?IDN" -r) 

		sleep 3		#5

		#less verbose; if arduino not found, this message just repeats
		if [ ${NoArduinoWarning} = 0 ]; then
			echo "(FindDevice) ${TTYPORT}  ?IDN: ${IDN}"  >> $PowControlLog
		fi

		#./CharReplace
		#if [ "`cat IDNCheck.txt`" = Arduino ]; then

		#skip if empty, otherwise cause misidentification
		if [ -z ${IDN} ]; then
		
		    #echo "skip empty IDN"
		    sleep 1

		
		elif [ ${IDN}=${ArduinoIDN} ]; then
		    
		    echo "(FindDevice) Arduino is found at: ${TTYPORT} ${IDN}" >> $PowControlLog

		    #save to text for other script
		    echo ${TTYPORT} > ${ArduinoIDNTxt}

		    #break all loops
		    ArduinoFound=1
		    NoArduinoWarning=0
		    searchACM=100; #leave while loop	

		    break

		else 
		    sleep 1
		fi
	    done

		#Arduino may be busy. wait
	    sleep 10
	    searchACM=$(($searchACM + 1))
	    
	done

	#cast warning if device not found after 3 trials
	if [ $ArduinoFound = 0 ]; then
		if [ ${NoArduinoWarning} = 0 ]; then
			echo "(FindDevice) Warning: Arduino NOT found" >> $PowControlLog
			#send mail
			echo $(date '+%Y/%0m/%0d %0H:%0M:%0S') "(FindDevice) Warning: Arduino NOT found" >> ${SysWarningMessageTxt}

			#prevent repeated warning
			NoArduinoWarning=1

			#empty the IDN txt
			echo "" > ${ArduinoIDNTxt}
		fi
		
		#wait longer
		sleep	60
	fi


done

	echo "(FindDevice) finished"  >> $PowControlLog

	return	$ArduinoFound
}

FindDevice $1


#echo "(FindDevice) running function Find() $1" >> $PowControlLog
#Find $1
#str=$?
#echo "(FindDevice) return value: $str"

#echo "Sending commands to ${TTYPORT}  ?IDN: ${IDN}" >> $PowControlLog
