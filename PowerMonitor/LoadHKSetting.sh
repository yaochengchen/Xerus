#S.H. Wang 2017 for TAROGE-2
#S.Y. Hsu 2017 for TAROGE-3
#define all common variables across multiple scripts related to HK

# naming convention for folder: 
#	TAROGE-3:  no trailing "/" 
#	TAROGE-4: with trailing "/" for clarity

# 2019 for TAROGE-4:
#	move directory and file definition to TarogeIOConstant.sh, and export as environment variables during installation
#. LoadHKSetting.sh

# some of definitions are briged with env var here in case individual HK tests are required

#!/bin/bash

PowControlDir="${TarogePowCtrlDir}"
	#"${TarogeDir}/PowerMonitor/"


#housekeeping file
PeriodHKTaking=48	#60, NOTICE: Taking all HKData from MPPT takes ~12s, so the period of taking the HKData is this $PeriodHKTaking + 11s.
HKDataDir="${TarogeHKDataDir}"	#"${TarogeDir}/hkData/"		#"${TarogeDir}/arduino-powercontrol/"
HKFilePrefix="${HKDataDir}/hkSummary"
HKFileExt=".txt"

#threshold for warning and shutdown
DiskSpaceLow_KB=1000000		#382965000  # 1765400000 for test in lab
TempOverheat=85		#85   #20 for lab test

#1count = $PeriodHKTaking+12s
Num_ShutPC=3
MaxNumOverheat=3
MaxNumLowDisk=3
MaxNumFailMPPT=20
	
#power control log
PowControlLog="${PowControlDir}/HKLog/PowControlLog-$(date '+%0Y%0m').txt"
ScriptFindDevice="${PowControlDir}/FindDevice.sh"
ScriptPowerOff=${TarogePowOffMacro}
	#"${PowControlDir}/PowerOff.sh"

#where arduino-serial is
ExeDir="${TarogePowCtrlDir}"
#	"${TarogeDir}/PowerMonitor/"

#Unified warnig message
DirSysWarning="${TarogeDir}/schedule/warning/"
SysWarningMessageTxt="${DirSysWarning}/warning_message.txt"
ScriptPowerOffMail="${TarogeDir}/schedule/mail_Shutdown.sh"

#arduino
#must set this correctly: ttyUSB or ttyACM 
ArduinoIDNTxt="${PowControlDir}/ArduinoIDN.txt"
ArduinoSerialCmd="${ExeDir}/arduino-serial"
ArduinoDevPrefix="/dev/ttyUSB"	#"/dev/ttyACM"	#
ArduinoIDN="Arduino"
ArduinoBaudRate=9600
NumRelay=14  #Not used in TAROGE-3

ArduinoWaitCount=3600		#each count = 1 sec; postponse wakeup process for PC cooldown in case of overheat

#test for DAQ interrupt
#DAQInterruptTxt0="${TarogeDir}/data/interrupt0.txt"
#DAQInterruptTxt="${TarogeDir}/data/interrupt.txt"	#TAROGE-2
#DAQInterruptTxt="${TarogeDir}/source/taroge2/DAQstate.txt"	#TAROGE-3
#Taroge-4:  $DAQStateTxt

#DAQ power 
# use env var
#PowerReadyTxt="${TarogeDir}/source/taroge2/PowerReady.txt"

