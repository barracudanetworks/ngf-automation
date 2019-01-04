#!/bin/bash
{
echo "Starting Cloud Init..."
echo "Change to static IP NGF: $NGFIP Netmask: $NGFNM Default Gateway: $NGFGW"
/opt/phion/bin/editconf -f /opt/phion/config/configroot/boxnet.conf -d REFS -s gendev_eth0
/opt/phion/bin/editconf -f /opt/phion/config/configroot/boxnet.conf -d RENAMED -s gendev_eth0
/opt/phion/bin/cloud-setmip $NGFIP $NGFNM $NGFGW
} >> /tmp/provision.log 2>&1