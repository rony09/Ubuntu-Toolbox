#!/bin/bash
#Auto-sec script
function userMatch {

}
function autoPass {
	#get actual users from passwd file
	#first extract the username and UUID
	awk -F':' '{print $1":"$3}' /etc/passwd | \
	#next, only allow UUID gretaer than 1000 through (ones less are system users)
	 grep ':[1-9][0-9]\{3\}$' | \
	 #then get rid of the UUID portion
	  cut -f 1 -d ':' | \
	   while read USER; do
		if ! grep -q $USER user.txt; then
    		printf "user $USER is not authorized!!!!\n"
		fi
	   done

}
function servRemove{
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
	#Enable update sources in /etc/apt/sources.list
	cat > sources.txt  <<EOF 
	deb http://security.ubuntu.com/ubuntu/ trusty-security main universe
	deb http://us.archive.ubuntu.com/ubuntu/ trusty-updates main universe
EOF
	cat /etc/apt/sources.list text.txt > sources.txt
	mv /etc/apt/sources.list /etc/apt/sources.list.bak
	mv sources.txt /etc/apt/sources.list
	#TBD modify /etc/apt/apt.conf.d/10periodic with the settings needed (1,1,0,1) (sed)
	# enable noncritical update check
	gsettings set com.ubuntu.update-notifier regular-auto-launch-interval 0
	#run upgrades
	sudo apt-get update
	sudo apt-get dist-upgrade -y
}
sudo cat /etc/shadow | \


