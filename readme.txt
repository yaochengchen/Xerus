=====================================
TAROGE DAQ installer

2019/10/06 Yaocheng Chen modified trigger related part: threshold step, table & scan


2019/05/19 Shih-Hao Wang

modified from 
	TAROGE-M installer
	2019/01/31 Shih-Hao Wang

package for TAROGE-4 DAQ on PC 

*setting environment variable and source script in ~/.bashrc
*make new folders and files for Taroge DAQ
*copy files and examples from installer
*
*documents for instructions
*backup scripts during R&D

---Prerequites---
	ROOT > ver 5 has to be installed and environment variables are set


	sudo apt-get install the following packages
		cmake	#compile DAQ program ps6000conT4
		net-tools  #if  ifconfig command is missing;  alternative use ip command
		mailutils   #sending mail
		postfix
		sshpass   #ssh without password; alternative: generate public key and copy to lab server
		sysv-rc-conf    # terminal user interface for managing /etc/rc{runlevel}.d/ symlinks.
		systememd-sysv   # for fast power off

	scipy for running python scripts in SnowShovel
		sudo apt-get install python-numpy python-scipy python-matplotlib ipython ipython-notebook python-pandas python-sympy python-nose


---How to install---

*** the existing files in ${TarogeDir} will be overwritten, please back up before running

	1. go to installer folder
		cd TarogeDAQInstaller
	2. run configureTarogeDAQ.sh with
		./configureTarogeDAQ.sh [full path to installer folder]

	the path where the program is installed
	TarogeDir=${HOME}/taroge

	the common variable is defined in 
	${TarogeDir}/TarogeIOConstant.h

	3. (optional) for running version of system, copy scripts in daemon/  to /etc/init.d, and modify crontab -e of local user and super user according to files in cron/. This is not automatically done by configureTarogeDAQ.sh



---How to update the installer---

* put the files into corresponding sub-folder in TarogeDAQInstaller, e.g., scripts to script/
* modify TarogeDAQInstaller/configureTarogeDAQ.sh if needed

=====================================



