#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

# Add hadoop user
addgroup hadoop
useradd -d /home/hduser -m -s /bin/bash -G hadoop hduser

# Configure SSH
apt-get install -y openssh-server
mkdir /var/run/sshd
su hduser -c "ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''"
su hduser -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
mv ./ssh_config /home/hduser/.ssh/config

DBG "Done!"
