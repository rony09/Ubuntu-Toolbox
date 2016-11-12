#!/bin/bash
# Auto-sec script V0.4b3
#############Disclaimer###############
# Please attribute if you copy. modify, or distribute
# No warranty, support, or guarantee has been provided for this script 
# Use at you own risk!

############CONFIG BLOCK##############
# Set these settings to match your installation details

# Set this to the codename of your Ubuntu (e.g. karmic, trusty, etc)
# leave blank if you want the script to automatically configure it
UBUNTU=""

# Set this to the name of the file that contains the usernames of the authorized users
# a default entry has been provided to the empty one supplied with the script
# NOTE: must be in same directory as this script
AUTH_USER_FILE="authusers.txt"

# Set this to the name of the file that contains the usernames of the authorized admins
# a default has been provided to the empty one supplied with the script
AUTH_ADMIN_FILE="authadmins.txt"

# Pasword to set for all users(at leat 8 digits, one cap, one number, one symbol):
# WRITE THIS DOWN!!!
PASSWORD="my_great_password"



###########Core Function Block#############
VERSION="V0.4b5"

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
	#find the unauthorized users by matching all the users with a authorized user list
	#dump the processed user list into a loop line by line
	printLog "Starting user matching operation" log/user.log /log/status.log
	cat alluser.txt | \
	while read USERDUMP; do
		if ! grep -q $USERDUMP $AUTH_USER_FILE; then
    		printLog "Unauthorized user found: $USERDUMP\n" log/user.log
    		echo $USERDUMP >> badusers.txt
		fi
	done
	printLog "user matching operation completed" log/status.log log/user.log
}
function adminChk {
	printLog "Starting Admin check operation" log/status.log log/user.log
	#backup IFS var
	IFSBAK=$IFS
	#grab current sudoers
	CURSUDO=$(cat /etc/group | grep ^sudo | cut -f 4- -d ':')
	#setup IFS to delimit based on commas
	IFS= ","
	for TESTADMIN in CURSUDO; do
		if ! grep -q $TESTADMIN $AUTH_ADMIN_FILE; then
		printLog "Unauthorized admin found: $TESTADMIN" log/user.log
		echo $TESTADMIN >> badadmin.txt
		fi
	done
	#restore IFS
	IFS=$IFSBAK
	printLog "Admin check finished" log/status.log log/user.log
}
function autoPass {
	printLog "Starting PassChange check operation" log/status.log log/passwordChanges.log
	cat alluser.txt | \
	while read USERDUMP; do
		if ! [ "$USERDUMP" == "$CUR_USER" ]; then
			printLog "Changing password for $USERDUMP to $PASSWORD" log/passwordChanges.log
			echo "$USERDUMP:$PASSWORD" | chpasswd #batch change the passwords
		fi
	done
}
function servRemove {
	ps | less
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
	# enable noncritical update check
	gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0
	# run upgrades
	  apt-get update >> log/updates.log
	  apt-get dist-upgrade -y | tee -a log/updates.log
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
cat alluser.txt
EOF
}

function setupIntEnv {
	echo "Welcome to the SecScrypt utility!"
	printf "Are you $USER? [Y/n]: " #test current user so we don't mess up its account
	read ANSWER
	if [ "$ANSWER" == "n" ] || [ "$ANSWER" == "N" ]; then
		printf "Please enter your username: "
		read CUR_USER
	else 
		CUR_USER=$USER
	fi
	echo "Hello $CUR_USER! You must have admin priviliges to use this program"
	echo "If you don't, then the script will fail"
	sleep 1s
	echo "Setting up"
	echo "Checking if you followed INSTRUCTIONS and ran this script as root..."
	if [ "$EUID" -ne 0 ]; then 
		echo "This script is not root. Run this script as ROOT!"
  		exit
  	else
  		echo "Script is root!"
	fi
	echo "Creating folders and files....."
	mkdir log
	printLog "SecScript started" log/status.log
	printf "Reading user list....."
	# call userdump
	userDump
	printf "[SUCCESS]\n"
	if [ "$UBUNTU" == "" ]; then
		UBUNTU=$(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d '=' -f 2)
	fi
	logFile "SecScript $VERSION initialized\n Current user is $CUR_USER" log/status.log
	echo "Done with setup!"
	sleep 2s
}


##############Main Block###############
setupIntEnv
while true; do
	echo "Sec Script $VERSION\n"
	echo "Please choose an option:"
	echo "1. Guided everything"
	echo "2. Unauthorized user remover"
	echo "3. Unauthorized admin remover"
	echo "4. User password changer"
	echo "5. Remove common servers"
	echo "6. Firewall"
	echo "7. Lost media file remover "
	echo "8. Enable update sources and update system"
	echo "9. PAM history setter"
	echo "u. Utility"
	echo "a. About"
	echo "d. Debug info"
	echo "q. Quit"
	printf "Choose an option: "
	read ANSWER
	case $ANSWER in 
		"1")
			echo "Sorry, this function has not been implemented yet!"
			;;
		"2")
			userMatch
			;;
		"3")
			adminChk
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
			echo
			;;
		"d")
			debugInfo
			;;
		"q")
			printLog "User requested script exit. Script exiting..." log/status.log
			exit 0
			;;
		*)
			echo "$ANSWER is not a option. Did you mistype something?"
			;;	
	esac
	sleep 2s
done