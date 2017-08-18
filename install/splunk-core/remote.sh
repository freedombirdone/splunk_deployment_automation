#!/bin/bash
#
# ===========================================================
# Purpose:	This script will remotely install the splunk uf
# Parameters:	${1} = path to splunk install .tgz file
#               ${2} = list of hosts to install the uf
# Example usage: $ bash splunkinstall.sh splunk-6.3.2-aaff59bb082c-Linux-x86_64.tgz
#
# Privileges:	Must be run as root
# Authors:	Anthony Tellez
#
# Notes:	This script can use customized Splunk install tar or the default from Splunk.com.
#       Our custom install comprised the following changes from the base install:
#		in ~/splunk/etc/system/local/
#			deploymentclient.conf - preloaded deployment server info
#		Alternatively, ~/splunk/etc/apps/
#		org_all_deploymentclient/local/
#			deploymentclient.conf - preloaded deployment server info
#		in ~/splunk/etc/
#			splunk-launch.conf - SPLUNK_FIPS=1 - this must be done on first boot to ensure splunk enables the FIPS module
#		after untar, splunk is started, the admin password is changed, and
#		splunk is set to run at boot time. Since everything up to this point was
#		done as the root user, we need to change ownership to the splunk user.
#		This is done via the chown command. Last step is to start splunk again.
#
# Revision:	Last change: 03/08/2016 by AT :: Increased Security of password entry mechanism
# ===========================================================
#
createSplunkUser="useradd -d /opt/splunk splunk"
untarSplunk="tar -zxvf /tmp/${1} -C /opt && chown -R splunk:splunk /opt/splunk"
startSplunk="sudo su - splunk -c 'touch /opt/splunk/etc/.ui_login && /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt'"
bootStart="/opt/splunk/bin/splunk enable boot-start -user splunk"
for HOST in $(< $2); do
    scp -r "${1}" $HOST:/tmp
    ssh $HOST "${createSplunkUser} && ${untarSplunk}"
    ssh $HOST "${startSplunk} && ${bootStart}"
	if [ $? -ne 0 ]; then
	  	echo "---- COULD NOT CONNECT TO $HOST ----"
	fi
done
