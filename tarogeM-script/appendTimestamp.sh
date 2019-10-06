#!/bin/bash
#appendTimestamp.sh for TAROGE-Melbourne
#S.H. Wang 2019-02
#
#the script modify the given file name by appending timestamp 
# used in threshold scan and event selection input
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"

#check number of arguments
if [ $# -ne 1  ] ; then
	echo "arguments: [file which name to be modified] "
	exit 1
else
	#remove file extension, append timestamp, append file extension
	TimeString=$( date -u '+%Y%0m%0d-%H%0M%0SZ')
	echo "append file name with timestamp: ${TimeString}"
	filename="${1%.*}-${TimeString}.${1##*.}"

	echo "new file name: ${filename}"
	if [ -f "$1" ]; then
		echo "modify file name: ${1} --> ${filename}"
		mv -v ${1}  ${filename}
	else
		echo " '${1}' not exist. no change"
	fi

fi
#file prefix for recognizing file type in folders


#echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"

