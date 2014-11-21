#!/bin/bash

function DBG {
	echo "=============> [`date`] $0: $1"
}

DBG "Starting"

apt-get install -y libfuse2

cd /tmp
apt-get download fuse
dpkg-deb -x fuse_* .
dpkg-deb -e fuse_*
rm fuse_*.deb
echo -en '#!/bin/bash\nexit 0\n' > DEBIAN/postinst
dpkg-deb -b . /fuse.deb
dpkg -i /fuse.deb

DBG "Done!"
