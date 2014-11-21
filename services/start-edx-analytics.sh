#!/bin/bash

/usr/sbin/sshd
su hduser -c "$HADOOP_HOME/sbin/start-dfs.sh"
su hduser -c "$HADOOP_HOME/sbin/start-yarn.sh"

cat << EOF > ./lms.json
        {
            "host": "$EDX_MYSQL_PORT_3306_TCP_ADDR",
            "port": "3306",
            "username": "$EDX_MYSQL_USERNAME",
            "password": "$EDX_MYSQL_PASSWORD"
        }
EOF
cat << EOF > ./local.json
        {
            "host": "localhost",
            "port": "3306",
            "username": "root",
            "password": ""
        }
EOF

su hduser -c "$HADOOP_HOME/bin/hdfs dfs -mkdir -p /edx-analytics-pipeline/output/"
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -mkdir -p /edx-analytics-pipeline/input/"
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -mkdir -p /edx-analytics-pipeline/packages/"
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -mkdir -p /data"
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -mkdir -p /tmp/luigi/partial/edx-analytics-pipeline/"
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -put ./local.json /edx-analytics-pipeline/output/local.json"
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -put ./lms.json /edx-analytics-pipeline/input/lms.json"
su hduser -c "$HADOOP_HOME/bin/hdfs dfs -put /tmp/edx-analytics-hadoop-util.jar /edx-analytics-pipeline/packages/edx-analytics-hadoop-util.jar"

cd /opt/edx-analytics-data-api ; ./manage.py runserver 0.0.0.0:8000 &

cd /opt/edx-analytics-dashboard ; ./manage.py runserver 0.0.0.0:9000 &

su hduser -c "/start-logwatch.sh"

