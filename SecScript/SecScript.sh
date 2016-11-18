#!/bin/bash
# Auto-sec script V0.4b5 -Now with passwording!

#############Disclaimer###############
# Please attribute if you copy, modify, or distribute
# This script has been provided "as is", and any implied or express warranties are discalimed 
# Use at your own risk!

############CONFIG BLOCK##############
# Set these settings to match your installation details

# Set this to the codename of your Ubuntu (e.g. karmic, trusty, etc)
# Leave blank if you want the script to automatically configure it
UBUNTU=""

# Set this to the name of the file that contains the usernames of the authorized users
# This should be a plaintext list with one username per line
# A default entry has been provided to the empty one supplied with the script
# NOTE: must be in same directory as this script
AUTH_USER_FILE="authusers.txt"

# Set this to the name of the file that contains the usernames of the authorized administrators
# This should be a plaintext list with one admin name per line
# A default has been provided to the empty one supplied with the script
AUTH_ADMIN_FILE="authadmins.txt"

# Password to set for all users(at leat 8 digits, one cap, one number, one symbol)
# WRITE THIS DOWN!!!
PASSWORD="my_great_password"

# Change this to false to silence any warning prompts before deleting 
# users groups or other dangerous script tasks
# WARNING THIS WILL ENABLE THE SCRIPT TO DELETE USERS PERMANENTLY WITHOUT WARNING!
INTERLOCK=true

# Log directory
# Change if you want it to somewhere other than ./log
LOGDIR="log"


###########Core Var Block#############
VERSION="V0.6b1" # Don't edit this!!!
STATUSLOG=$LOGDIR"/status.log"
USERLOG=$LOGDIR"/user.log"
PASSLOG=$LOGDIR"/password.log"
BADUSERFILE="tmp/badusers"
BADADMINFILE="tmp/badadmins"

###########Core Function Block#############
function printLog {
	MESSAGE="$1"
	echo $MESSAGE
	shift
	while [ "$1" !=  "" ]; do 
		echo "["$(date +%Y/%m/%d_%H:%M:%S)"] "$MESSAGE >> $1
		shift
	done
}
function logFile {
	MESSAGE="$1"
	shift
	while [ "$1" !=  "" ]; do 
		echo "["$(date +%Y/%m/%d_%H:%M:%S)"] "$MESSAGE >> $1
		shift
	done
}

###############Function Block#############
function userDump {
	# printLog "Reading user files" /etc/status.log /etc/user.log
	# get actual users from passwd file
	# first extract the username and UID
	awk -F':' '{print $1":"$3}' /etc/passwd | \
	# next only select UIDs greater than 1000 through (ones less are system users)
	 grep -E ':[1-9][0-9]{3}$' | \
	 # then get rid of the UID portion and put the users in a file
	  cut -f 1 -d ':' > alluser.txt
}
function userMatch {
	if [ -e "$BADUSERFILE" ]; then
		rm $BADUSERFILE
	fi
	#find the unauthorized users by matching all the users with a authorized user list
	#dump the processed user list into a loop line by line
	printLog "Starting user matching operation" "$USERLOG" "$STATUSLOG"
	cat alluser.txt | \
	while read USERDUMP; do
		if ! grep -q "^"$USERDUMP"$" $AUTH_USER_FILE; then
    		printLog "Unauthorized user found: $USERDUMP" "$USERLOG"
    		echo $USERDUMP >> $BADUSERFILE
		fi
	done
	printLog "user matching operation completed" "$STATUSLOG" "$USERLOG"
}
function adminChk {
	if [ -e "$BADADMINFILE"]; then
		rm $BADADMINFILE
	fi
	printLog "Starting Admin check operation" "$STATUSLOG" "$USERLOG"
	#backup IFS var
	IFSBAK=$IFS
	#grab current sudoers
	CURSUDO=$(cat /etc/group | grep ^sudo | cut -f 4- -d ':')
	#setup IFS to delimit based on commas
	IFS=","
	for TESTADMIN in "$CURSUDO"; do
		if ! grep -q "^"$TESTADMIN"$" $AUTH_ADMIN_FILE; then
		printLog "Unauthorized admin found: $TESTADMIN" "$USERLOG"
		echo $TESTADMIN >> $BADADMINFILE
		fi
	done
	#restore IFS
	IFS=$IFSBAK
	printLog "Admin check finished" "$STATUSLOG" "$USERLOG"
}
function autoPass {
	printLog "Starting PassChange operation" "$STATUSLOG" "$PASSLOG"
	cat alluser.txt | \
	while read USERDUMP; do
		if ! [ "$USERDUMP" == "$CUR_USER" ]; then
			printLog "Changing password for $USERDUMP to $PASSWORD" "$PASSLOG"
			echo "$USERDUMP:$PASSWORD" | chpasswd #batch change the passwords
		fi
	done
}
function servRemove {
	ps -ef | grep [v]sftpd
	apt-get purge netcat -y
	apt-get purge samba -y
	apt-get purge vsftpd -y
	apt-get autoremove -y
}
function firewall {
	apt-get install gufw -y
	ufw enable
}
function updateSys {
	sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
	# Enable update sources in /etc/apt/sources.list
	echo "deb http://security.ubuntu.com/ubuntu/ $UBUNTU-security main universe" >> /etc/apt/sources.list
	echo "deb http://us.archive.ubuntu.com/ubuntu/ $UBUNTU-updates main universe" >> /etc/apt/sources.list
	# TODO modify /etc/apt/apt.conf.d/10periodic and 50unattended-upgrades with the settings needed (1,1,0,1) (sed)
	if [grep -q "APT::Periodic::Unattended-Upgrade.*" /etc/apt/apt.d.conf/10periodic]; then
		sed -i s/APT::Periodic::Unattended-Upgrade .*\;/APT::Periodic::Unattended-Upgrade "1"\;/ /etc/apt/apt.conf.d/10periodic
	else
		echo "APT::Periodic::Unattended-Upgrade "1"\;" >> /etc/apt/apt.comf.d/10periodic
	fi
	# enable noncritical update check
	gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0
	# run upgrades
	  apt-get update >> log/updates.log
	  apt-get dist-upgrade -y | tee -a log/updates.log
}
function delUsers {
	echo "The following users will be PERMANENTLY DELETED:"
	cat $BADUSERFILE
	echo "Options: y=yes; n=no(default); s=Let me choose"
	read -p "Delete users?(N/y/s): " ANSWER
	case "$ANSWER" in
		[Nn])
			echo "Ok. No users will be deleted"
			logFile "Operator canceled deletion of users"
			;;
		[Yy])
			cat $BADUSERFILE |\
			while read USERNM; do
				printLog "Deleting user $USERNM" log/user
				userdel $USERNM
			done
			;;
		[Ss])
			for $USERNM in $BADUSERFILE; do
				echo "Do you want to delete user $USERNM?"
				read -p "y=yes, n=no, a=all (Y/n/a): " ANSWER
				case $ANSWER in
					[Yy])
						userdel $USERNM
						;;
					[Nn])
						printLog "User overrode deletion of $USERNM. Not deleting." "$USERLOG"
						;;
					*)
						echo "Mangled input, assuming no"
						printLog "User overrode deletion of $USERNM. Not deleting." "$USERLOG"
						;;
				esac
			done
			;;
		*)
			echo "$ANSWER is not a option. Assuming you didn't want to do anything."
			echo "No users will be deleted"
			logFile "Mangled operator input. Deletion of users canceled" "$USERLOG"
			;;
	esac
}

function demAdmin {
	echo: "The following admins will be have admin priviliges revoked:"
	cat $BADADMINFILE
	echo "Options: y=yes; n=no(default); s=Let me choose"
	read -p "Demote admins?(N/y/s): " ANSWER
	case "$ANSWER" in
		[Nn])
			echo "Ok. No modifications will be made to admins"
			logFile "Operator canceled demotion of of admins"
			;;
		[Yy])
			cat $BADADMINFILE |\
			while read USERNM; do
				printLog "Demoting admin $USERNM" log/user
				deluser $USERNM sudo
			done
			;;
		[Ss])
			for $USERNM in $BADUSERFILE; do
				echo "Do you want to revoke admin priviliges from user $USERNM?"
				read -p "y=yes, n=no, a=all (Y/n/a): " ANSWER
				case $ANSWER in
					[Yy])
						deluser $USERNM sudo
						;;
					[Nn])
						printLog "User overrode demotion of $USERNM. Not deleting." "$USERLOG"
						;;
					*)
						echo "Mangled input, assuming no"
						printLog "User overrode demotion of $USERNM. Not deleting." "$USERLOG"
						;;
				esac
			done
			;;
		*)
			echo "$ANSWER is not a option. Assuming you didn't want to do anything."
			echo "No admins will have priviliges revoked"
			logFile "Mangled operator input. Demotion of admins canceled" "$USERLOG"
			;;
	esac
}

function debugInfo {
cat <<EOF
DEBUG INFO

VAR Dumps:
Ubuntu codename: $UBUNTU
Current user: $CUR_USER
Authorized user file: $AUTH_USER_FILE
Authorized admin file: $AUTH_ADMIN_FILE

USERS found:
$(cat alluser.txt)
EOF
}

function cleanup {
	printLog "Interupt recieved, exiting...." /"$STATUSLOG"
	rm $BADUSERFILE
	rm $BADADMINFILE
	exit
}

function setupIntEnv { # setup initial environment
	echo "Welcome to the SecScrypt utility!"
	printf "Are you $USER? [Y/n]: " # test current user so we don't mess up its account
	read ANSWER
	if [ "$ANSWER" == "n" ] || [ "$ANSWER" == "N" ]; then
		printf "Please enter your username: "
		read CUR_USER
	else 
		CUR_USER=$USER
	fi
	echo "Hello $CUR_USER! You must have admin priviliges to use this script"
	echo "If you don't, then the script will fail"
	sleep 1s
	echo -e "\nSetting up..."
	echo "Checking if you followed INSTRUCTIONS and ran this script as root..."
	if [ "$EUID" -ne 0 ]; then 
		echo "This script is not root. Run this script as ROOT!"
  		exit
  	else
  		echo "Script is root!"
	fi
	echo "Creating folders and files....."
	mkdir log tmp
	logFile "SecScript $VERSION starting in interactive mode..." "$STATUSLOG"
	printLog "Building user list..." "$STATUSLOG"
	userDump
	printLog "Checking ubuntu codename..." "$STATUSLOG"
	if [ "$UBUNTU" == "" ]; then
		UBUNTU=$(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d '=' -f 2)
		printLog "Ubuntu codename found: $UBUNTU" "$STATUSLOG"
	else 
		printLog "Manual Ubuntu codename override found: $UBUNTU"
	fi
	logFile "SecScript $VERSION initialized" "$STATUSLOG"
	logFile "User is $CUR_USER" "$STATUSLOG"
	echo "Done with setup!"
	sleep 2s
}

function utilityMenu {
	while true; do
		echo "Sec Script $VERSION"
		echo "UTILITY MENU:"
		echo "Please choose an option:"
		echo "1. Check for servers(listening ports) using netstat"
		echo "2. Search for a custom process/file"
		echo "3. Identify the location and type of a command"
		echo "d. Debug information"
		echo "q. Quit this menu and go back to the main menu"
		read -p "Choose an option: " ANSWER
		case $ANSWER in
			"1")
				netstat -tulnp
				;;
			"2")
				read -p "Enter process/file/deamon to find: " ANSWER
				PROCLIST=ps -ef | grep $ANSWER | grep -v "grep"
				if [! $PROCLIST]; then
					echo "Process not found. Searching filesystem for match..."
					updatedb
					locate $ANSWER
				else
					echo $PROCLIST
				fi
				;;
			"3")
				read -p "Enter name of command to identify: " ANSWER
				type -a $ANSWER
				;;
			"d")
				debugInfo
				;;
			"q")
				break
				;;
			*)
				echo "$ANSWER is not a option. Did you mistype something?"
				;;
		esac
		sleep 2
	done
}
##############Main Block###############
trap cleanup SIGINT
setupIntEnv
while true; do
	echo "Sec Script $VERSION"
	echo "MAIN MENU:"
	echo "1. Guided everything"
	echo "2. Unauthorized user remover"
	echo "3. Unauthorized admin remover"
	echo "4. User password changer"
	echo "5. Remove common servers"
	echo "6. Firewall"
	echo "7. Lost media file remover "
	echo "8. Enable update sources and update system"
	echo "9. PAM history setter"
	echo "a. About"
	echo "u. Utility"
	echo "q. Quit" 
	read -p "Choose an option: " ANSWER
	case $ANSWER in 
		"1")
			echo "Sorry, this function has not been implemented yet!"
			;;
		"2")
			userMatch
			delUsers
			;;
		"3")
			adminChk
			demAdmin
			;;
		"4")
			autoPass
			;;
		"5")
			servRemove
			;;
		"6") 
			firewall
			;;
		"7") 
			echo "Sorry, this function has not been implemented yet!"
			;;
		"8")
			updateSys
			;;
		"a")
			echo ""
			;;
		"u")
			utilityMenu
			;;
		"q")
			printLog "User requested script exit. Script exiting..." "$STATUSLOG"
			exit 0
			;;
		*)
			echo "$ANSWER is not a option. Did you mistype something?"
			;;	
	esac
	sleep 2s
done