#!/bin/bash

/usr/sbin/sshd
su hduser -c "$HADOOP_HOME/sbin/start-dfs.sh"
su hduser -c "$HADOOP_HOME/sbin/start-yarn.sh"

cd /opt/edx-analytics-data-api ; ./manage.py runserver 0.0.0.0:8000 &


cd /opt/edx-analytics-dashboard ; ./manage.py runserver 0.0.0.0:9000 &

su hduser -c "/start-logwatch.sh"

