#!/bin/bash -x
exec > >(tee -a /var/tmp/repo-node-init_$$.log) 2>&1

. /usr/local/osmosix/etc/.osmosix.sh
. /usr/local/osmosix/etc/userenv
. /usr/local/osmosix/service/utils/cfgutil.sh
. /usr/local/osmosix/service/utils/agent_util.sh

dlFile () {
    agentSendLogMessage  "Attempting to download $1"
    if [ -n "$dlUser" ]; then
        agentSendLogMessage  "Found user ${dlUser} specified. Using that and specified password for download auth."
        wget --no-check-certificate --user $dlUser --password $dlPass $1
    else
        agentSendLogMessage  "Didn't find username specified. Downloading with no auth."
        wget --no-check-certificate $1
    fi
    if [ "$?" = "0" ]; then
        agentSendLogMessage  "$1 downloaded"
    else
        agentSendLogMessage  "Error downloading $1"
        exit 1
    fi
}

agentSendLogMessage "Username: $(whoami)" # Should execute as cliqruser
agentSendLogMessage "Working Directory: $(pwd)"

defaultGitTag="cloudcenter-fullinstall"
if [ -n "$gitTag" ]; then
    agentSendLogMessage  "Found gitTag parameter gitTag = ${gitTag}"
else
     agentSendLogMessage  "Didn't find custom parameter gitTag. Using gitTag = ${defaultGitTag}"
     gitTag=${defaultGitTag}
fi

agentSendLogMessage  "CloudCenter release ${ccRel} selected."

agentSendLogMessage  "Installing OS Prerequisits wget vim java-1.8.0-openjdk nmap"
sudo mv /etc/yum.repos.d/cliqr.repo ~
sudo yum install -y wget rsync

# Download necessary files
cd /tmp
agentSendLogMessage  "Downloading installer files."
dlFile ${baseUrl}/installer/repo_installer.bin

sudo chmod +x repo_installer.bin
agentSendLogMessage  "Running repo installer"
sudo ./repo_installer.bin centos7 ${cloudType} repo

agentSendLogMessage  "Syncing repo. This will take a while, maybe 15-60 minutes.
 If you want to see what's going on, login and look at /tmp/repo_sync.log"
sudo su repo -c "/usr/bin/repo_sync.sh"