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
	sleep 1
	echo "."
done