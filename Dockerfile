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

# Prepare fuse for JDK install
RUN apt-get install -y libfuse2
RUN cd /tmp ; apt-get download fuse
RUN cd /tmp ; dpkg-deb -x fuse_* .
RUN cd /tmp ; dpkg-deb -e fuse_*
RUN cd /tmp ; rm fuse_*.deb
RUN cd /tmp ; echo -en '#!/bin/bash\nexit 0\n' > DEBIAN/postinst
RUN cd /tmp ; dpkg-deb -b . /fuse.deb
RUN cd /tmp ; dpkg -i /fuse.deb

# Install Java dependencies
ENV JAVA_HOME /usr/lib/jvm/jdk
RUN apt-get install -y openjdk-7-jdk maven
RUN ln -s /usr/lib/jvm/java-7-openjdk-amd64 $JAVA_HOME

# Add hadoop user
RUN addgroup hadoop
RUN useradd -d /home/hduser -m -s /bin/bash -G hadoop hduser

# Configure SSH
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN su hduser -c "ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''"
RUN su hduser -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
ADD config/ssh_config ./ssh_config
RUN mv ./ssh_config /home/hduser/.ssh/config

# Setup Hadoop
ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_DATA /var/lib/hadoop
RUN wget https://archive.apache.org/dist/hadoop/core/hadoop-2.3.0/hadoop-2.3.0.tar.gz
RUN tar zxvf hadoop-2.3.0.tar.gz
RUN mv hadoop-2.3.0 /usr/local/hadoop-2.3.0
RUN ln -s /usr/local/hadoop-2.3.0 $HADOOP_HOME
RUN rm -rf hadoop-2.3.0*
RUN mkdir $HADOOP_HOME/logs
RUN mkdir -p $HADOOP_DATA/2.3.0/data $HADOOP_DATA/current/data
RUN ln -s $HADOOP_DATA/2.3.0/data $HADOOP_DATA/current/data

# Export Hadoop environment variables
ENV PATH $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV YARN_HOME $HADOOP_HOME

RUN echo "export JAVA_HOME=$JAVA_HOME" >> /home/hduser/.bashrc
RUN echo "export HADOOP_HOME=$HADOOP_HOME" >> /home/hduser/.bashrc
RUN echo "export PATH=$PATH" >> /home/hduser/.bashrc
RUN echo "export HADOOP_MAPRED_HOME=$HADOOP_MAPRED_HOME" >> /home/hduser/.bashrc
RUN echo "export HADOOP_COMMON_HOME=$HADOOP_COMMON_HOME" >> /home/hduser/.bashrc
RUN echo "export HADOOP_HDFS_HOME=$HADOOP_HDFS_HOME" >> /home/hduser/.bashrc
RUN echo "export YARN_HOME=$YARN_HOME" >> /home/hduser/.bashrc

# Configure HDFS
ADD config/core-site.xml ./core-site.xml
ADD config/hdfs-site.xml ./hdfs-site.xml
ADD config/hadoop-env.sh ./hadoop-env.sh
RUN rm -f $HADOOP_HOME/etc/hadoop/core-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN mv ./core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
RUN mv ./hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
RUN mv ./hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN mkdir -p $HADOOP_DATA/current/data/hdfs/namenode $HADOOP_DATA/current/data/hdfs/datanode

# Configure YARN
ADD config/yarn-site.xml ./yarn-site.xml
ADD config/mapred-site.xml ./mapred-site.xml
RUN rm -f $HADOOP_HOME/etc/hadoop/yarn-site.xml
RUN mv ./yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
RUN mv ./mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml

# Build protobuf
RUN wget https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.gz
RUN tar zxvf protobuf-2.5.0.tar.gz
RUN cd protobuf-2.5.0 ; \
    ./configure --prefix=/usr/local ; \
    make ; \
    make install
RUN rm -rf protobuf-2.5.0*
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/usr/local/lib

# Build Hadoop Common
RUN wget https://github.com/apache/hadoop-common/archive/release-2.3.0.tar.gz
RUN mv release-2.3.0.tar.gz hadoop-common-release-2.3.0.tar.gz
RUN tar zxvf hadoop-common-release-2.3.0.tar.gz
RUN cd hadoop-common-release-2.3.0/hadoop-common-project ; mvn package -X -Pnative -DskipTests
RUN mv $HADOOP_HOME/lib/native/libhadoop.a $HADOOP_HOME/lib/native/libhadoop32.a
RUN mv $HADOOP_HOME/lib/native/libhadoop.so $HADOOP_HOME/lib/native/libhadoop32.so
RUN mv $HADOOP_HOME/lib/native/libhadoop.so.1.0.0 $HADOOP_HOME/lib/native/libhadoop32.so.1.0.0
RUN cd hadoop-common-release-2.3.0/hadoop-common-project/hadoop-common/target/native/target/usr/local/lib ; \
    mv libhadoop.a $HADOOP_HOME/lib/native/libhadoop.a ; \
    mv libhadoop.so $HADOOP_HOME/lib/native/libhadoop.so ; \
    mv libhadoop.so.1.0.0 $HADOOP_HOME/lib/native/libhadoop.so.1.0.0
RUN rm -rf hadoop-common-release-2.3.0*

# Configure directory ownership
RUN chown -R hduser:hduser /home/hduser
RUN chown -R hduser:hadoop $HADOOP_HOME/ $HADOOP_DATA/
RUN chmod 1777 /tmp

# Format namenode
RUN su hduser -c "$HADOOP_HOME/bin/hdfs namenode -format"

# Copy start-hadoop script
ADD services/start-hadoop.sh ./start-hadoop.sh
RUN mv ./start-hadoop.sh /usr/local/hadoop/bin/start-hadoop.sh

# HDFS ports
EXPOSE 50070 50470 9000 50075 50475 50010 50020 50090

# YARN ports
EXPOSE 8088 8032 50060

# Git clone edx-analytics-pipeline
RUN apt-get install -y git python-pip python-dev
RUN cd /opt ; git clone -b gabe/docker-experiment https://github.com/edx/edx-analytics-pipeline
RUN cd /opt/edx-analytics-pipeline ; WHEEL_PYVER=2.7 WHEEL_URL=http://edx-wheelhouse.s3-website-us-east-1.amazonaws.com/Ubuntu/precise make system-requirements install

# prepare HDFS storage
#RUN sudo -u hduser /usr/local/hadoop/bin/hdfs dfs -mkdir /data

# Configure LUIGI
ADD config/luigi-client.cfg ./luigi-client.cfg
RUN mkdir -p /etc/luigi
RUN mv ./luigi-client.cfg /etc/luigi/client.cfg

# Build Hive
RUN wget https://archive.apache.org/dist/hive/hive-0.11.0/hive-0.11.0-bin.tar.gz
RUN tar zxvf hive-0.11.0-bin.tar.gz
RUN mv ./hive-0.11.0-bin /opt
RUN rm -rf ./hive-0.11.0-bin*

# Configure Hive
ENV HIVE_HOME /opt/hive-0.11.0-bin
ENV PATH $HIVE_HOME/bin:$PATH
RUN echo "export HIVE_HOME=$HIVE_HOME" >> /home/hduser/.bashrc
RUN echo "export PATH=$PATH" >> /home/hduser/.bashrc

# Build Sqoop
ENV SQOOP_HOME /usr/lib/sqoop
ENV SQOOP_LIB $SQOOP_HOME/lib
RUN wget http://www.carfab.com/apachesoftware/sqoop/1.4.5/sqoop-1.4.5.bin__hadoop-2.0.4-alpha.tar.gz
RUN tar zxvf sqoop-1.4.5.bin__hadoop-2.0.4-alpha.tar.gz
RUN mv ./sqoop-1.4.5.bin__hadoop-2.0.4-alpha $SQOOP_HOME
RUN rm -rf ./sqoop-1.4.5.bin__hadoop-2.0.4-alpha*

# Build mysql connector
RUN wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.29.tar.gz
RUN tar zxvf mysql-connector-java-5.1.29.tar.gz
RUN mkdir -p $SQOOP_LIB
RUN mv ./mysql-connector-java-5.1.29/mysql-connector-java-5.1.29-bin.jar $SQOOP_LIB/
RUN sudo ln -s $SQOOP_HOME/bin/sqoop /usr/bin/sqoop
RUN rm -rf ./mysql-connector-java-5.1.29*

# Build edx-analytics-data-api
RUN git -C /opt clone https://github.com/edx/edx-analytics-data-api
RUN cd /opt/edx-analytics-data-api ; make develop ; ./manage.py migrate --noinput ; ./manage.py migrate --noinput --database=analytics ; ./manage.py set_api_key edx edx

# Build edx-insights
RUN git -C /tmp clone https://github.com/edx/djeventstream ; cd /tmp/djeventstream ; python setup.py install ; rm -rf /tmp/djeventstream
RUN git -C /tmp clone https://github.com/edx/loghandlersplus ; cd /tmp/loghandlersplus ; python setup.py install ; rm -rf /tmp/loghandlersplus
RUN apt-get -y install python-pip python-matplotlib python-scipy emacs mongodb apache2-utils python-mysqldb subversion ipython nginx git redis-server
RUN git -C /opt clone https://github.com/edx/insights ; cd /opt/insights ; pip install -r requirements.txt ; cd src ; service mongodb start ; python manage.py syncdb ; python manage.py migrate

# data api and insights ports
EXPOSE 8000 9022

# global loop script
ADD services/start-edx-analytics.sh ./start-edx-analytics.sh
CMD ["/bin/bash", "/start-edx-analytics.sh"]
