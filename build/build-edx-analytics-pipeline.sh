#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

apt-get install -y git python-pip python-dev tmux mysql-server-5.6
cd /opt
git clone -b gabe/docker-experiment https://github.com/edx/edx-analytics-pipeline
cd edx-analytics-pipeline
WHEEL_PYVER=2.7 WHEEL_URL=http://edx-wheelhouse.s3-website-us-east-1.amazonaws.com/Ubuntu/precise make system-requirements install
cp config/docker.cfg override.cfg
chown -R hduser:hadoop .

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
echo "export HIVE_HOME=$HIVE_HOME" >> /home/hduser/.bashrc

# Build Sqoop
cd /
wget http://www.carfab.com/apachesoftware/sqoop/1.4.5/sqoop-1.4.5.bin__hadoop-2.0.4-alpha.tar.gz
tar zxvf sqoop-1.4.5.bin__hadoop-2.0.4-alpha.tar.gz
mv ./sqoop-1.4.5.bin__hadoop-2.0.4-alpha $SQOOP_HOME
rm -rf ./sqoop-1.4.5.bin__hadoop-2.0.4-alpha*
echo "export SQOOP_HOME=$SQOOP_HOME" >> /home/hduser/.bashrc
echo "export SQOOP_LIB=$SQOOP_LIB" >> /home/hduser/.bashrc

# Build mysql connector
cd /
wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.29.tar.gz
tar zxvf mysql-connector-java-5.1.29.tar.gz
mkdir -p $SQOOP_LIB
mv ./mysql-connector-java-5.1.29/mysql-connector-java-5.1.29-bin.jar $SQOOP_LIB/
sudo ln -s $SQOOP_HOME/bin/sqoop /usr/bin/sqoop
rm -rf ./mysql-connector-java-5.1.29*

# Build hadoop utils
cd /opt
git clone https://github.com/mulby/edx-analytics-hadoop-util
cd edx-analytics-hadoop-util
javac -cp `$HADOOP_HOME/bin/hadoop classpath` org/edx/hadoop/input/ManifestTextInputFormat.java
jar cf /tmp/edx-analytics-hadoop-util.jar org/edx/hadoop/input/ManifestTextInputFormat.class

DBG "Done!"
