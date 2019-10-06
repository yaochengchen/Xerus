#!/bin/bash
#
#S.H. Wang 2019-01
#set up communication with SST via USB and Ethernet
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"
TimeString=$( date -u '+%Y%0m%0d-%H%0M%0S')  

#in case global constants are not loaded
.  ${TarogeMDir}/TarogeMIOConstant.sh

SnTCPComm=${SnScriptOnlineDir}/AriTcpProtocol.py

TCPLog="${LogDir}/log-tcp-${TimeString}.txt"

#run at background
python ${SnTCPComm}  >  ${TCPLog}

sleep 20

#regular monitoring
while true; 
do

	#kill and re-run if corrupted

	#pidof not work for python
	#tcppidlist=$(pidof -x ${SnTCPComm})
	pid=$( ps -ef | grep "AriTcpProtocol.py" | grep -v "grep" | awk '{print $2}' )

	#for pid in ${tcppidlist}; do
	if [ -z ${pid} ]; then
		echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :${0} : no running ${SnTCPComm} macro. submit"
		TimeString=$( date -u '+%Y%0m%0d-%H%0M%0S') 
		TCPLog="${LogDir}/log-tcp-${TimeString}.txt"
		python ${SnTCPComm}   > ${TCPLog}
	else
        echo "$(date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC :${0} : Process ${SnTCPComm} is already running with PID ${pid}."
        if [ $? -ne 0 ] ; then	#$? not really worked if python throw exception
			echo "kill process pid : ${pid}" >>  ${TCPLog}
			kill  ${pid}

			TimeString=$( date -u '+%Y%0m%0d-%H%0M%0S') 
			TCPLog="${LogDir}/log-tcp-${TimeString}.txt"
			python ${SnTCPComm}   > ${TCPLog}    
		else
			#debug
			echo "$( date -u '+%Y-%0m-%0d %H:%0M:%0S') : TCP comm:  No problem"
		fi   	
    fi

	sleep 300

done 

echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"
