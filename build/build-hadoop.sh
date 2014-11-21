#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

# Setup Hadoop
cd /
if [ ! -d "hadoop-2.3.0" ]; then
	wget https://archive.apache.org/dist/hadoop/core/hadoop-2.3.0/hadoop-2.3.0.tar.gz
	tar zxvf hadoop-2.3.0.tar.gz
fi
mv hadoop-2.3.0 /usr/local/hadoop-2.3.0
ln -s /usr/local/hadoop-2.3.0 $HADOOP_HOME
rm -rf hadoop-2.3.0*
mkdir $HADOOP_HOME/logs
mkdir -p $HADOOP_DATA/2.3.0/data $HADOOP_DATA/current/data
ln -s $HADOOP_DATA/2.3.0/data $HADOOP_DATA/current/data

# Export Hadoop environment variables
echo "export JAVA_HOME=$JAVA_HOME" >> /home/hduser/.bashrc
echo "export HADOOP_HOME=$HADOOP_HOME" >> /home/hduser/.bashrc
echo "export PATH=$PATH" >> /home/hduser/.bashrc
echo "export HADOOP_MAPRED_HOME=$HADOOP_MAPRED_HOME" >> /home/hduser/.bashrc
echo "export HADOOP_COMMON_HOME=$HADOOP_COMMON_HOME" >> /home/hduser/.bashrc
echo "export HADOOP_HDFS_HOME=$HADOOP_HDFS_HOME" >> /home/hduser/.bashrc
echo "export YARN_HOME=$YARN_HOME" >> /home/hduser/.bashrc

# Configure HDFS
DBG "`ls -l /usr/local/hadoop`"
rm -f $HADOOP_HOME/etc/hadoop/core-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hadoop-env.sh
mv ./core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
mv ./hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
mv ./hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
mkdir -p $HADOOP_DATA/current/data/hdfs/namenode $HADOOP_DATA/current/data/hdfs/datanode

# Configure YARN
cd /
rm -f $HADOOP_HOME/etc/hadoop/yarn-site.xml
mv ./yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
mv ./mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml

wget https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz
tar zxvf protobuf-2.5.0.tar.gz
cd protobuf-2.5.0 ; \
	./configure --prefix=/usr/local ; \
	make ; \
	make install
cd /
rm -rf protobuf-2.5.0*

# Build Hadoop Common
cd /
wget https://github.com/apache/hadoop-common/archive/release-2.3.0.tar.gz
mv release-2.3.0.tar.gz hadoop-common-release-2.3.0.tar.gz
tar zxvf hadoop-common-release-2.3.0.tar.gz
cd hadoop-common-release-2.3.0/hadoop-common-project ; mvn package -X -Pnative -DskipTests
mv $HADOOP_HOME/lib/native/libhadoop.a $HADOOP_HOME/lib/native/libhadoop32.a
mv $HADOOP_HOME/lib/native/libhadoop.so $HADOOP_HOME/lib/native/libhadoop32.so
mv $HADOOP_HOME/lib/native/libhadoop.so.1.0.0 $HADOOP_HOME/lib/native/libhadoop32.so.1.0.0
cd hadoop-common-release-2.3.0/hadoop-common-project/hadoop-common/target/native/target/usr/local/lib ; \
	mv libhadoop.a $HADOOP_HOME/lib/native/libhadoop.a ; \
	mv libhadoop.so $HADOOP_HOME/lib/native/libhadoop.so ; \
	mv libhadoop.so.1.0.0 $HADOOP_HOME/lib/native/libhadoop.so.1.0.0
rm -rf hadoop-common-release-2.3.0*

# Configure directory ownership
chown -R hduser:hduser /home/hduser
chown -R hduser:hadoop $HADOOP_HOME/ $HADOOP_DATA/
chmod 1777 /tmp

# Format namenode
su hduser -c "$HADOOP_HOME/bin/hdfs namenode -format"

# Create /data dfs DIR
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -mkdir /data"

# Copy start-hadoop script
mv ./start-hadoop.sh /usr/local/hadoop/bin/start-hadoop.sh

DBG "Done!"
