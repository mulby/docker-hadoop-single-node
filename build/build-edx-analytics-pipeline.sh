#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

apt-get install -y git python-pip python-dev
cd /opt
git clone -b gabe/docker-experiment https://github.com/edx/edx-analytics-pipeline
cd edx-analytics-pipeline
WHEEL_PYVER=2.7 WHEEL_URL=http://edx-wheelhouse.s3-website-us-east-1.amazonaws.com/Ubuntu/precise make system-requirements install

# Configure LUIGI
cd /
mkdir -p /etc/luigi
mv ./luigi-client.cfg /etc/luigi/client.cfg

# Configure Hive
cd /
wget https://archive.apache.org/dist/hive/hive-0.11.0/hive-0.11.0-bin.tar.gz
tar zxvf hive-0.11.0-bin.tar.gz
mv ./hive-0.11.0-bin /opt
rm -rf ./hive-0.11.0-bin*

# Build Sqoop
cd /
wget http://www.carfab.com/apachesoftware/sqoop/1.4.5/sqoop-1.4.5.bin__hadoop-2.0.4-alpha.tar.gz
tar zxvf sqoop-1.4.5.bin__hadoop-2.0.4-alpha.tar.gz
mv ./sqoop-1.4.5.bin__hadoop-2.0.4-alpha $SQOOP_HOME
rm -rf ./sqoop-1.4.5.bin__hadoop-2.0.4-alpha*

# Build mysql connector
cd /
wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.29.tar.gz
tar zxvf mysql-connector-java-5.1.29.tar.gz
mkdir -p $SQOOP_LIB
mv ./mysql-connector-java-5.1.29/mysql-connector-java-5.1.29-bin.jar $SQOOP_LIB/
sudo ln -s $SQOOP_HOME/bin/sqoop /usr/bin/sqoop
rm -rf ./mysql-connector-java-5.1.29*

DBG "Done!"
