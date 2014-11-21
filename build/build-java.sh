#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

apt-get install -y openjdk-7-jdk maven
ln -s /usr/lib/jvm/java-7-openjdk-amd64 $JAVA_HOME

DBG "Done!"
