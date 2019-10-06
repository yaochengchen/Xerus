#!/bin/bash
#
#S.H. Wang 2019-01
#
#set up communication with SST via USB and Ethernet
# top-level script runinning after startup
#
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"
TimeString=$( date -u '+%Y%0m%0d-%H%0M%0S')  
#in case global constants are not loaded
.  ${TarogeMDir}/TarogeMIOConstant.sh

#station const

MbedUSBPath="/dev/ttyACM0"

#USB is problematic on BBB
USBCommMacro=${DAQScriptDir}/runUSBComm.sh
TCPCommMacro=${DAQScriptDir}/runTCPComm.sh

#run at background
 ${TCPCommMacro}  &  

#MBed will be reset (power cycle)
# ${USBCommMacro}  & 

 #check if previous script is running
#from stackoverflow
#for pid in $(pidof -x ${TCPCommMacro}); do
#	#exclude the current script
#    if [ ${pid} != $$ ]; then
#    	#man bash: $$ Expands to the process ID of the shell. In a () subshell, it expands to the process #ID of the current shell, not the subshell.
#        echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :${TCPCommMacro} : Process is already #running with PID ${pid}.  skip this run."
#        exit 1
#    fi
#done


echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"
#addConfToQueue.py

#processRawData.py
#clearStationQueue.py
#TarogeM-autoSetThermalThreshold.py
#request DAQ log