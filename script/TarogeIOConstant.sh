#!/bin/bash

#should be hard-coded just in case??
#TarogeDir should be set up by configureTarogeM.sh

#UserDir="/home/banana"
#$(pwd ~)
#this is set first in configureTarogeM.sh

#this will cause user-dependent path (e.g., debian or root with sudo)
#--------------------
export TarogeDir=/home/taroge4/taroge
#--------------------
#source common variables
#source ${TarogeDir}/TarogeMIOConstant.sh

#${0} for name of this script
#-u for UTC
# echo "(TarogeMIOConstant.sh) $( date -u '+%Y/%0m/%0d %H:%0M:%0S') UTC: start ${0}"


#--------- Parameter setting

#data transfer (rsync) setting,   schedule/rsync.sh
#--------- remote Directory setting: where to get data from server
# rsync destination
#export ServerTopDir="/home/taroge"
export TarogeLabServerUser="taroge"
export TarogeLabServerIP="140.112.104.83"
export TarogeLabServerPort="50000"
#Seagate 8TB HDD
export TarogeLabServerDir="/home/taroge/data/Taroge4/Taroge4"
export TarogeLabServerStatDir="/home/taroge/data/Taroge4-DataTransfer"
export TarogeGmail="taroge2@gmail.com"
#export PublicIP="198.161.168.235"
#export InmarsatModemIP="192.168.128.100"
#MBed is the MCU on SST board which MAC uniquely specify the data flow
#export BBBIP="192.168.128.101" 
#export MbedMacAddress="0002F7F2DA83"

#file prefix for recognizing file type in folders
#title for identifying setup files
# email-related
export TarogeStationName="Taroge4"
#export ScanTitle="Scan"

#--------- local Directory setting
#where data are stored
export TarogeDataDir="${TarogeDir}/data"
export TarogeTrigDataDir="${TarogeDir}/trigger"
export TarogeHKDataDir="${TarogeDir}/hkData"
export TarogeLogDir="${TarogeDir}/log"
export TarogeSampleDir="${TarogeDir}/sample"

#where the DAQ program are
export TarogeDAQDir="${TarogeDir}/daq"
export TarogeTrigDir="${TarogeDAQDir}/trigger"
export TarogeScriptDir="${TarogeDir}/script"
export TarogeScheduleDir="${TarogeDir}/schedule"
export TarogeWarningDir="${TarogeScheduleDir}/warning"
export TarogeScheduleLogDir="${TarogeScheduleDir}/schedule_log"

#for management,  DAQ script related to SST operation is separated from station-wise scripts
export TarogePowCtrlDir="${TarogeDir}/PowerMonitor"

export TarogeTestDir="${TarogeDir}/test"

#where calibration and configuration files are stored
#export EventSelectDir="${TarogeDir}/eventSelection"

#store processed data


#--------- Macro setting
#station operation
#export NetworkConfigMacro="${BBBScriptDir}/set_network.sh"


#top DAQ process
export TarogeDAQMacro="${TarogeDAQDir}/runTaroge.sh"
export TarogeDAQExe="${TarogeDAQDir}/ps6000conT4"

#trigger threshold scan
export TarogeThreshScanMacro="${TarogeTrigDir}/labrun_t4.sh"


#for power control, housekeeping, watchdog
export TarogeHKSetupMacro="${TarogePowCtrlDir}/LoadHKSetting.sh"
export TarogePowMonMacro="${TarogePowCtrlDir}/PowerMonitor.sh"
export TarogePowOffMacro="${TarogePowCtrlDir}/PowerOff.sh"

#
export InterruptDAQMacro="${TarogeDAQDir}/interruptDAQ.sh"

#data transfer: including rsync.h and rsync_remove_src_file_weekly.sh
export TarogeRsyncMacro="${TarogeScheduleDir}/runRsync.sh"


#--------- File setting
#export ThreshScanInput="ThreshodScanInput.txt"
#state for threshold scan / regular data taking
export DAQStateTxt="${TarogeDAQDir}/DAQstate.txt"
export TarogeRunNumTxt="${TarogeDAQDir}/TarogeRunNum.txt"
export PowerReadyTxt="${TarogeDAQDir}/PowerReady.txt"

#trigger setting
export VTrigOffsetFile="${TarogeDAQDir}/Voffset.dat"


# at Lab server !  data transfer status: get rsynced to DAQ PC
export TarogeLabDatStatTxt="taroge4-transferStatus-server.txt"
export TarogeStnDatStatTxt="taroge4-transferStatus-station.txt"
export TarogeLabServDatStat="${TarogeLabServerStatDir}/${TarogeLabDatStatTxt}"

#ThreshScanOutput=""
#export NewRawDataList="${EventSelectDir}/NewRawDataList.txt"
#export DefEventSelectInput="${EventSelectDir}/DefaultEventSelectCut.txt"
#export SelectFileCounter="${EventSelectDir}/SelectFileCounter.txt"
#export LatestDAQConfigTxt="${EventSelectDir}/LatestDAQConfig.txt"

#--------- Timer setting
# alternative: crontab <--- how to change its config remotely?
#Inmarsat comm. 
#SendDataPeriodSec=3600

#period for checking data and run event selection
#use crontab instead
#DataCheckPeriodSec=600

#voltage, 2x SSR state, CPU temperature, SD card space
#BBBHKCheckPeriodSec=1800