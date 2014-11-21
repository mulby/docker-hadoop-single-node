#!/bin/bash

/usr/sbin/sshd
su hduser -c "$HADOOP_HOME/sbin/start-dfs.sh"
su hduser -c "$HADOOP_HOME/sbin/start-yarn.sh"

su hduser -c "$HADOOP_HOME/bin/hdfs dfs -put /tmp/edx-analytics-hadoop-util.jar /edx-analytics-pipeline/packages/edx-analytics-hadoop-util.jar"

cd /opt/edx-analytics-data-api ; ./manage.py runserver 0.0.0.0:8000 &

service mongodb start

cd /opt/insights/src ; python manage.py runserver 0.0.0.0:9022
