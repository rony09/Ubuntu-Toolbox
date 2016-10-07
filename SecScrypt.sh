#!/bin/bash
# Auto-sec script V0.3b
#############Disclaimer###############
# Please attribute if you copy. modify, or destribute
# No warranty, support, or guarantee has been provided for this script 
# Use at you own risk!

############CONFIG BLOCK##############
# Set these settings to match your installation details

# Set this to the codename of your Ubuntu (e.g. karmic, trusty, etc)
# CHANGE THIS!!!!!
UBUNTU="Ubuntu_Version"

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

###########Function Block################
function userDump {
	#get actual users from passwd file
	#first extract the username and UID
	awk -F':' '{print $1":"$3}' /etc/passwd | \
	#next only select UIDs greater than 1000 through (ones less are system users)
	 grep ':[1-9][0-9]\{3\}$' | \
	 #then get rid of the UID portion and put the users in a file
	  cut -f 1 -d ':' > alluser.txt
}
function userMatch {
	#find the unauthorized users by matching all the users with a authorized user list
	#dump the processed user list into a loop line by line
	cat alluser.txt | \
	while read USERDUMP; do
		if ! grep -q $USERDUMP $AUTH_USER_FILE; then
    		printf "user $USERDUMP is not authorized!!!!\n"
    		echo $USERDUMP >> badusers.txt
    	else
    		echo $USERDUMP >> verauth.txt
		fi
	done
}
function adminChk {
	#backup IFS var
	IFSBAK=$IFS
	#grab current sudoers
	CURSUDO=$(cat /etc/group | grep ^sudo | cut -f 4- -d ':')
	#setup IFS to delimit based on commas
	IFS= ","
	for TESTADMIN in CURSUDO; do
		if ! grep -q $TESTADMIN $AUTH_ADMIN_FILE; then
		prinf "Admin $TESTADMIN in not authorized!!\n"
		echo $TESTADMIN >> badadmin.txt
		fi
	done
	#restore IFS
	IFS=$IFSBAK
}
function autoPass {
	cat alluser.txt | \
	while read USERDUMP; do
		if ! $USERDUMP -eq $CUR_USER; then 
			echo "Changing password for $USERDUMP to $PASSWORD"
			echo "Changing password for $USERDUMP to $PASSWORD" >> log/passwordChanges.log
			echo "$USERDUMP:$PASSWORD" | sudo chpasswd #batch change the passwords
		fi
	done
}
function servRemove {
	ps | less
	sudo apt-get purge netcat -y
	sudo apt-get purge samba -y
	sudo apt-get purge vsftpd -y
	sudo apt-get autoremove -y
}
function firewall {
	sudo apt-get install gufw -y
	sudo ufw enable
}
function updateSys {
	sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
	# Enable update sources in /etc/apt/sources.list
	sudo sh -c "echo deb http://security.ubuntu.com/ubuntu/ $UBUNTU-security main universe >> /etc/apt/sources.list"
    sudo sh -c "echo deb http://us.archive.ubuntu.com/ubuntu/ $UBUNTU-updates main universe >> /etc/apt/sources.list"
	# TODO modify /etc/apt/apt.conf.d/10periodic and 50unattended-upgrades  with the settings needed (1,1,0,1) (sed)
	# enable noncritical update check
	gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0
	# run upgrades
	sudo apt-get update
	sudo apt-get dist-upgrade -y
}


##############Main Block###############
echo "Welcome to the SecScrypt utility!"
printf "Are you $USER? [Y/n]: " #test current user so we don't mess up its account
read ANSWER
if ANSWER -eq "n"; then
	printf "Please enter your username: "
	read CUR_USER
else 
	CUR_USER=$USER
fi
echo "Hello $CUR_USER! You must have admin priviliges to use this program"
mkdir log
# call userdump 