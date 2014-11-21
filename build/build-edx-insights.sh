#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

cd /
git -C /tmp clone https://github.com/edx/djeventstream ; cd /tmp/djeventstream ; python setup.py install ; rm -rf /tmp/djeventstream

git -C /tmp clone https://github.com/edx/loghandlersplus ; cd /tmp/loghandlersplus ; python setup.py install ; rm -rf /tmp/loghandlersplus

apt-get -y install python-pip python-matplotlib python-scipy emacs mongodb apache2-utils python-mysqldb subversion ipython nginx git redis-server

git -C /opt clone https://github.com/edx/insights ; cd /opt/insights ; pip install -r requirements.txt ; cd src ; service mongodb start ; python manage.py syncdb ; python manage.py migrate


DBG "Done!"
