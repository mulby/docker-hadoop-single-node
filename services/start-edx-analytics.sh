#!/bin/bash

/usr/sbin/sshd
su hduser -c "$HADOOP_HOME/sbin/start-dfs.sh"
su hduser -c "$HADOOP_HOME/sbin/start-yarn.sh"

sudo -u hduser /usr/local/hadoop/bin/hdfs dfs -mkdir /data

cd /opt/edx-analytics-data-api ; ./manage.py runserver 0.0.0.0:8000 &

service mongodb start

cd /opt/insights/src ; python manage.py runserver 0.0.0.0:9022
