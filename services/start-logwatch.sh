#!/bin/bash

WATCHDIR=~hduser/logs

#IFS=""
mkdir -p "$WATCHDIR"
cd "$WATCHDIR"

if [ "`pwd`" != "$WATCHDIR" ]; then
	echo "wrong pwd : is $WATCHDIR ok?"
	exit -1
fi

while [ true ]; do
	IDX=0
	for i in `find . -type f`; do
		echo "=======================> $i"
		F="tracking.log-`date +%Y%m%d-%H%M%S`-$IDX"
		mv "$i" "$F"
		gzip "$F"
		/usr/local/hadoop/bin/hdfs dfs -copyFromLocal "$F".gz /data/"$F".gz
		rm -f "$F".gz
		((IDX++))
	done
	if [ $IDX -gt 0 ]; then
		launch-task ImportCourseDailyFactsIntoMysql --local-scheduler --src hdfs://localhost:9000/data/ --dest hdfs://localhost:9000/edx-analytics-pipeline/enroll/ --lib-jar hdfs://localhost:9000/edx-analytics-pipeline/packages/edx-analytics-hadoop-util.jar --manifest hdfs://localhost:9000/edx-analytics-pipeline/manifest/enroll.manifest --n-reduce-tasks 1 --name enroll --overwrite
	fi
	sleep 1
	echo "."
done