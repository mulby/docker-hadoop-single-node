#
# Open edX Analytics Pipeline Dockerfile (Hadoop 2.3.0)
#

FROM ubuntu:14.04
MAINTAINER Anthony Smith

# Prepare the operating system
RUN apt-get update
RUN apt-get upgrade -y

# Install dependencies
RUN apt-get install -y llvm-gcc build-essential make cmake automake autoconf libtool zlib1g-dev

# Build Fuse
ADD build/build-fuse.sh /tmp/
RUN bash -c /tmp/build-fuse.sh

### Build Java deps
ENV JAVA_HOME /usr/lib/jvm/jdk
ADD build/build-java.sh /tmp/
RUN bash -c /tmp/build-java.sh

### Build Hadoop user + OpenSSH
ADD config/ssh_config ./ssh_config
ADD build/build-openssh+hduser.sh /tmp/
RUN bash -c /tmp/build-openssh+hduser.sh

### Build Hadoop (friends and family...)
ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_DATA /var/lib/hadoop
# Export Hadoop environment variables
ENV HIVE_HOME /opt/hive-0.11.0-bin
ENV SQOOP_HOME /usr/lib/sqoop
ENV SQOOP_LIB $SQOOP_HOME/lib
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV YARN_HOME $HADOOP_HOME
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin
# Configure HDFS
ADD config/core-site.xml ./core-site.xml
ADD config/hdfs-site.xml ./hdfs-site.xml
ADD config/hadoop-env.sh ./hadoop-env.sh
# Configure YARN
ADD config/yarn-site.xml ./yarn-site.xml
ADD config/mapred-site.xml ./mapred-site.xml
# Build protobuf
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/lib
# Copy start-hadoop script
ADD services/start-hadoop.sh ./start-hadoop.sh
#RUN mv ./start-hadoop.sh /usr/local/hadoop/bin/start-hadoop.sh
ADD packages/hadoop-2.3.0.tar.gz /
RUN ls -l /
ADD build/build-hadoop.sh /tmp/
RUN bash -c /tmp/build-hadoop.sh

# Build edx-analytics-pipeline (+ luigi conf)
ADD config/luigi-client.cfg ./luigi-client.cfg
ADD build/build-edx-analytics-pipeline.sh /tmp/
RUN bash -c /tmp/build-edx-analytics-pipeline.sh

# Build edx-analytics-data-api
ADD build/build-edx-analytics-data-api.sh /tmp/
RUN bash -c /tmp/build-edx-analytics-data-api.sh

# Build edx-analytics-dashboard
ADD build/build-edx-analytics-dashboard.sh /tmp/
RUN bash -c /tmp/build-edx-analytics-dashboard.sh

# HDFS ports (50070 50470 9000 50075 50475 50010 50020 50090)
# YARN ports (8088 8032 50060)
# data api (8000)
# dashboard (9022)
EXPOSE 50070 50470 9000 50075 50475 50010 50020 50090 8000 9000

# global loop script
ADD services/start-edx-analytics.sh ./start-edx-analytics.sh
#CMD ["/bin/bash", "/start-edx-analytics.sh"]
