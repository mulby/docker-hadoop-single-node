#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

# Add demokey to hduser
su hduser -c "cat /demokey.pub >> ~/.ssh/authorized_keys"
rm /demokey.pub

DBG "Done!"
