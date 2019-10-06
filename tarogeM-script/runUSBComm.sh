#!/bin/bash
#
#S.H. Wang 2019-01
#
#set up communication with SST via USB and Ethernet
# level 2 script runinning and montoring
#
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"
TimeString=$( date -u '+%Y%0m%0d-%H%0M%0S')

USBLog="${LogDir}/log-usb-${TimeString}.txt"

#in case global constants are not loaded
.  ${TarogeMDir}/TarogeMIOConstant.sh
  
#station const

MbedUSBPath="/dev/ttyACM0"

#in casethere's USB hub on BBB and more than one device are found
 # unliikely for a station, but likely for test on PC
#looping 
for file in /dev/ttyACM*; do
    echo "$(basename "$file")"
done

#if
#
#else 
#	#wait if not found. maybe the device is still loading
#	sleep(20)
#fi

#run at background
python ${SnUSBComm} ${MbedUSBPath}  >  ${USBLog}

sleep 20

#regular monitoring
while true; 
do

	#kill and re-run if corrupted
	#$? not really worked if python throw exception
	if [ $? -ne 0 ] ; then
		pid=$( ps -ef | grep "AriUsbProtocol.py" | grep -v "grep" | awk '{print $2}' )
		echo "kill process pid : ${pid}" >>  ${USBLog}
		kill  ${pid}

		TimeString=$( date -u '+%Y%0m%0d-%H%0M%0S') 
		USBLog="${LogDir}/log-tcp-${TimeString}.txt"
		python ${SnUSBComm}  & > ${USBLog}

	else 
		echo "$( date -u '+%Y-%0m-%0d %H:%0M:%0S') : USB comm: No problem"
	fi

	sleep 60

done 

#lost the device

echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"

#request DAQ log