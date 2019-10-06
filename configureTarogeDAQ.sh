#!/bin/bash
#
#S.H. Wang 2019-01-31 for TAROGE-M
#			2019-05-09 for TAROGE-4 DAQ
#for faster installation and configuring Taroge DAQ 
# --------------- TarogeDir is set here and overwrite TarogeIOConstant.h

# create folders given list of folder names

#02/20 replace .bashrc () by .profile (log-in, better for env. variables)
#02/18 add EventSelectDir to LD_LIBRARY_PATH
#02/02 add  /root/.bashrc


#local home;  
UserDir=${HOME}
echo "UserDir = ${HOME}"
#"/home/banana"

#${0} for name of this script
#-u for UTC
echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"

#source directory where scripts to be copied
#should be full path
SourceDir=${1}
if [ ! -d "${SourceDir}" ] ; then
	echo "Error: arg1=SourceDir: ${SourceDir} not exist"
	exit 1
fi

#source common variables

#modify ~/.profile
#TarogeM constants
TarogeDir="${UserDir}/taroge"
TarogeIOConstant="TarogeIOConstant.sh"


echo "check TarogeDir: ${TarogeDir}"
if [ ! -d "${TarogeDir}" ] ; then
	mkdir -v  ${TarogeDir}
fi

#-n not override
#-i interactive
# ######## override for update############
cp -v -i ${SourceDir}/script/${TarogeIOConstant}  ${TarogeDir}

#save/overwrite  TarogeDir path to TarogeIOConstant.sh
#use alias to avoid setting of SnowShovel

echo "overwrite TarogeDir=${TarogeDir}  in ${TarogeDir}/${TarogeIOConstant}"


#/c\ Replace the selected lines with text,
#since variables contain slash, use semicolon as delimiter for sed
sed -i "s:export TarogeDir=.*:export TarogeDir=${TarogeDir}:g" ${TarogeDir}/${TarogeIOConstant}

. ${TarogeDir}/${TarogeIOConstant}


#move TarogeIOConstant.sh to script/
# ${TarogeScriptDir} not defined in .profile
#mv -v ${TarogeDir}/${TarogeIOConstant} ${TarogeScriptDir}

#copy to /etc/init.d for startup daemon (may not desired by test PC)
#require additional header
#sudo cp -i -v   ${TarogeDir}/${TarogeIOConstant} /etc/init.d

#it is recommended to put definition in bashrc and source it in .profile because .profile is not loaded in non-login shell
#setting TarogeDir:  don't overwrite if already exists! (may cause problem during test)
TMinProfile=$(grep 'export TarogeDir' ${HOME}/.bashrc)
if [ -z "${TMinProfile}" ]; then

	#TarogeDir="${UserDir}/tarogeM"

   	echo "add TarogeDir = ${TarogeDir} to ~/.bashrc"
   	echo "append TarogeIOConstant.sh in ~/.bashrc"
 #  	echo "export LD_LIBRARY_PATH=${EventSelectDir}:${LD_LIBRARY_PATH}"
   #TarogeDir should be defined first to get IOConstant, and then variables inside
	echo "export TarogeDir=${TarogeDir}" >> ${HOME}/.bashrc
	echo ". \${TarogeDir}/TarogeIOConstant.sh" >> ${HOME}/.bashrc   	
	#add LD_LIBRARY_PATH for event selection	  *.so
#	echo "export LD_LIBRARY_PATH=\${EventSelectDir}:\${LD_LIBRARY_PATH}" >> ${HOME}/.bashrc
else
	echo "Found TarogeDir at: ${TMinProfile} : ${TarogeDir}"
	#override
fi

#user
#TMinEnv=$(grep 'TarogeIOConstant.sh' ${HOME}/.profile)
#if [ -z "${TMinEnv}" ]; then
#
#   echo "append TarogeIOConstant.sh in ~/.profile"
#   echo "source ${TarogeDir}/TarogeIOConstant.sh" >> ${HOME}/.profile
#else
#	echo ${TMinEnv}
#fi

 #update
#source not work 
#source ${HOME}/.profile
. ${HOME}/.bashrc

####### for su  required by some commands
#TMinRootProfile=$(sudo grep 'export TarogeDir' /root/.profile)
#if [ -z "${TMinRootProfile}" ]; then
#
#   	echo "add TarogeDir = ${TarogeDir} to /root/.profile"
#	echo "append TarogeIOConstant.sh to /root/.profile"
#	echo "append LD_LIBRARY_PATH: ${LD_LIBRARY_PATH} to /root/.profile"
#
#	sudo echo "export TarogeDir=${TarogeDir}" >> /root/.profile
#   	sudo echo ". \${TarogeDir}/TarogeIOConstant.sh" >> /root/.profile
#	sudo echo "export LD_LIBRARY_PATH=\${EventSelectDir}:\${LD_LIBRARY_PATH}" >> /root/.profile
#
#else
#	echo "Found TarogeDir at: ${TMinRootProfile} : ${TarogeDir}"
#
#fi

####### for su  required by some commands
#TMinRootEnv=$(sudo grep 'TarogeIOConstant.sh' ~/.profile)
#if [ -z "${TMinEnv}" ]; then
#
#   echo "append TarogeIOConstant.sh in /root/.profile"
#   echo "source ${TarogeDir}/TarogeIOConstant.sh" >> /root/.profile
#
#else
#	echo ${TMinRootEnv}
#fi

#sudo . /root/.profile


#a smarter way is parsing line by line in TarogeIOConstant.h and create new folder accordingly
#create new if not exists


#modify varialble value in python scripts may be risky
#AriStage.py   STAGE_DIR="/data/ONLINE/Stage" 
#AriDataOrganizer.py

echo "create folders in ${TarogeDir}"
#--------- Directory setting
#data
echo "create data folders"

if [ ! -d "${TarogeDataDir}" ] ; then
	mkdir -v ${TarogeDataDir}
fi

if [ ! -d "${TarogeTrigDataDir}" ] ; then
	mkdir -v ${TarogeTrigDataDir}
fi

if [ ! -d "${TarogeHKDataDir}" ] ; then
	mkdir -v ${TarogeHKDataDir}
fi

if [ ! -d "${TarogeLogDir}" ] ; then
	mkdir -v ${TarogeLogDir}
fi


#store processed data
echo "create folders in DAQ program"

if [ ! -d "${TarogeDAQDir}" ] ; then
	mkdir -v ${TarogeDAQDir}
fi

if [ ! -d "${TarogeTrigDir}" ] ; then
	mkdir -v ${TarogeTrigDir}
fi

if [ ! -d "${TarogeScriptDir}" ] ; then
	mkdir -v ${TarogeScriptDir}
fi


if [ ! -d "${TarogeScheduleDir}" ] ; then
	mkdir -v ${TarogeScheduleDir}
fi

if [ ! -d "${TarogeWarningDir}" ] ; then
	mkdir -v ${TarogeWarningDir}
fi

if [ ! -d "${TarogeScheduleLogDir}" ] ; then
	mkdir -v ${TarogeScheduleLogDir}
fi

if [ ! -d "${TarogePowCtrlDir}" ] ; then
	mkdir -v ${TarogePowCtrlDir}
fi

if [ ! -d "${TarogeTestDir}" ] ; then
	mkdir -v ${TarogeTestDir}
fi
#create folders if not exist 


#copy macro from source to destination
#--------- Macro setting
#use existing python scripts in SnowShovel
# ${SNS}: path to SnowShovel
#-n no override existing files


#if [ ! -f "${HOME}/.rootrc" ] ; then
#	cp -v snowScript/.rootrc  ${HOME}
#fi

echo "copy DAQ programs to ${TarogeDAQDir}"
cp -rv  ${SourceDir}/daq/  ${TarogeDir}
cp -rv  ${SourceDir}/schedule/  ${TarogeDir}
cp -rv  ${SourceDir}/script/  ${TarogeDir}
cp -rv  ${SourceDir}/PowerMonitor/  ${TarogeDir}
#export LatestDAQConfigTxt="${EventSelectDir}/LatestDAQConfig.txt"
#export DefEventSelectInput="${EventSelectDir}/DefaultEventSelectCut.txt"


#export IsTMScanTxt="${TarogeDir}/IsTMScan.txt"
#echo "create Scan state txt:"
#echo "0" > ${IsTMScanTxt}
#export IsSSTCommTxt="${TarogeDir}/IsSSTComm.txt"


#create default DAQ config; 
#echo "SST" > ${LatestDAQConfigTxt}
#echo "${EvtSelTitle}	${DefEventSelectInput}" >> ${LatestDAQConfigTxt}
#echo "${ScanTitle}	" >> ${LatestDAQConfigTxt}
#copy all scripts in subfolders  DAQScriptDir  and BBBScriptDir
echo "copy script/*"
#cp  -v ${SourceDir}/script/DAQ/*   ${DAQScriptDir}

#cp  -i -v ${SourceDir}/script/BBB/*   ${BBBScriptDir}

cp -v  "$(cd "$(dirname "$0")" ; pwd -P )/$0"  ${TarogeScriptDir}


echo "copy config/*"
#cp -v ${SourceDir}/config/*   ${ArchiveConfigDir}



#copy document folder and files
cp -rv  ${SourceDir}/doc   ${TarogeDir}

#compile macros...

#change permission: 3-bits 4= read (r), 2=write (w), 1=execute

#775 for directories,  774 for files
#-type f for file,  d for folders
#-exec command {} +
#  This  variant  of  the  -exec action runs the specified command on the selected files, but the command
#  line is built by appending each selected file name at the end; the total number of invocations of  the
#  command  will  be  much  less than the number of matched files.  The command line is built in much the
#  same way that xargs builds its command lines.  Only one instance of `{}' is allowed  within  the  com‐
#  mand.  The command is executed in the starting directory.
find ${TarogeDir} -type d -exec chmod 775 {} +
find ${TarogeDir} -type f -exec chmod 774 {} +

#--------- File setting
#EventSelectInput="${EventSelectDir}/DefaultEventSelectCut.txt"
#SelectEventList="${EventSelectDir}/SelectEventList.txt"

#cp -v ${SourceDir}/eventSelection/DefaultEventSelectCut.txt ${EventSelectInput}
#don't overwrite existing HK txt 

#----- compile DAQ program
#this is neccessary as the env var called by getenv() can be different
echo "compile DAQ program ps6000conT4..."

originalPath=$(pwd)
cd ${TarogeDAQDir}
rm ${TarogeDAQDir}/CMakeCache.txt
cmake .
make

cd ${originalPath}

echo "$( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: finish ${0}"
