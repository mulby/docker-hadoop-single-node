#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

#apt-get install -y npm
git -C /opt clone https://github.com/edx/edx-analytics-dashboard
cd /opt/edx-analytics-dashboard
pip install -r requirements.txt
make develop
make migrate

DBG "Done!"
