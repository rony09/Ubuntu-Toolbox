#!/bin/bash

#Auto-sec script V0.2b2

########CONFIG BLOCK###########
# Set these settings to match your installation details

# Set this to the codename of your Ubuntu (e.g. karmic, trusty, etc)
UBUNTU="trusty"

# Set this to the name of the file that contains the usernames of the authorized users
# An empty one has been provided with the script
# NOTE: must be in same directory as this script
AUTH_USER_FILE="authusers.txt"

###########Function Block################
function userDump {
	#get actual users from passwd file
	#first extract the username and UUID
	awk -F':' '{print $1":"$3}' /etc/passwd | \
	#next only allow UUID gretaer than 1000 through (ones less are system users)
	 grep ':[1-9][0-9]\{3\}$' | \
	 #then get rid of the UUID portion and put it in a file
	  cut -f 1 -d ':' > alluser.txt
}
function userMatch {
	#dump the processed user list into a loop line by line
	cat alluser.txt | \
	while read USERDUMP; do
		if ! grep -q $USERDUMP $AUTH_USER_FILE; then
    		printf "user $USERDUMP is not authorized!!!!\n"
		fi
	done
}
function autoPass {
	cat alluser.txt | \
	while read USERDUMP; do
		if ! $USERDUMP -eq $CUR_USER; then 
			echo "Changing password for $USERDUMP to $PASSWORD"
			echo "$USERDUMP:$PASSWORD" | sudo chpasswd #batch change the passwords
		fi
	done
}
function servRemove {
	sudo apt-get purge netcat -y
	sudo apt-get purge samba -y
	sudo apt-get purge vsftpd -y
	sudo apt-get autoremove
}
function firewall {
	sudo apt-get install gufw
	sudo ufw enable
}
function updateSys {
	sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
	#Enable update sources in /etc/apt/sources.list
	sudo sh -c "echo deb http://security.ubuntu.com/ubuntu/ $UBUNTU-security main universe >> /etc/apt/sources.list"
    sudo sh -c "echo deb http://us.archive.ubuntu.com/ubuntu/ $UBUNTU-updates main universe >> /etc/apt/sources.list"
	#TODO modify /etc/apt/apt.conf.d/10periodic and 50unattended-upgrades  with the settings needed (1,1,0,1) (sed)
	# enable noncritical update check
	gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0
	#run upgrades
	sudo apt-get update
	sudo apt-get dist-upgrade -y
}


##############Main Block###############
echo "Welcome to the SecScrypt utility!"
printf "Are you $USER? [Y/n]: "
read ANSWER
if ANSWER -eq n; then
	printf "Please enter your username: "
	read CUR_USER
else 
	CUR_USER=$USER
fi
