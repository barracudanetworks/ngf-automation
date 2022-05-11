#!/bin/bash
##############################################################################################################
#  ____                                      _       
# | __ )  __ _ _ __ _ __ __ _  ___ _   _  __| | __ _ 
# |  _ \ / _` | `__| `__/ _` |/ __| | | |/ _` |/ _` |
# | |_) | (_| | |  | | | (_| | (__| |_| | (_| | (_| |
# |____/ \__,_|_|  |_|  \__,_|\___|\__,_|\__,_|\__,_|
#                                                    
#!/bin/bash
# Azure ipconfig failover script.
#
# AUTHOR: Gemma Allen (gallen@barracuda.com)
# LASTEDIT: 2021-03-03
#
##############################################################################################################
# This script is to be triggered by the Virtual Server and runs upon start up of the Virtual Server

# Local logging adapt the LOGDIR variable to the directory where script is installed.

TODAY=`date +"%Y-%m-%d %T"`
DATE=`date +"%Y-%m-%d"`
LOGDIR="/phion0/logs"
LOG="$LOGDIR/ipconfig_switch.log"

# Email Notification
SMTPNOTIFICATION=true
SMTPSERVER="[EMAIL-SERVER]"
FROM="[EMAIL-FROM]"
TO="[EMAIL-TO]"
SUBJECT="IPCONFIG Switch Result - CloudGen Firewall F-Series - $TODAY"

echo "-------------------------------------------------------------------------" 
  echo " IPConfig switch script for Barracuda CloudGen Firewall F-Series" 
  echo " Date: $TODAY" 
  echo " see $LOG for more details"
  echo "-------------------------------------------------------------------------" 

echo "$TODAY - Supplied PIP : $PIP" >> $LOG 2>&1
echo "$TODAY - Supplied IPCONFIG: $IPCONFIG" >> $LOG 2>&1
COUNTER=0
CONFPATH="/opt/phion/config/active/"

    #authenticates to the CLI uisng the system identity
    #Get VM name
    VM=$(curl -sH Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2021-01-01&format=text")
    echo "$TODAY - This VM is $VM" >> $LOG 2>&1
    RG=$(curl -sH Metadata:true "http://169.254.169.254/metadata/instance/compute/resourceGroupName?api-version=2021-01-01&format=text")
    echo "$TODAY - Current Resource Group: $RG" >> $LOG 2>&1
    az login --identity >> $LOG 2>&1
    #SPID=$(az resource list -n $VM --query [*].identity.principalId --out tsv)

    #Collects NIC info for both boxes
    NICID=$(az vm show --name $VM -g $RG --query 'networkProfile.networkInterfaces[0].id' -o tsv)
    echo "$TODAY - Current NIC ID $NICID" >> $LOG 2>&1
    #Get the other NIC Name
    NIC=$(az network nic show --ids $NICID --query "name" -o tsv)
    echo "$TODAY - Get current NIC $NIC" >> $LOG 2>&1

    IPCONFIGS=$(az network nic ip-config list -g $RG --nic-name $NIC --query "[*].{name: name}" -o tsv)

    #Iterates through the IP Configurations assigned to the first NIC
    for NAME in $(az network nic ip-config list -g $RG --nic-name $NIC --query "[*].{name: name}" -o tsv)
    do
        #Get's the IP for that IP config
        IP=$(az network nic ip-config list -g $RG --nic-name $NIC --query "[?name=='$NAME'].privateIpAddress" -o tsv)
        echo $IP

    echo "${CONFPATH}external.boxnet_altip_${NAME}.conf" >> $LOG 2>&1
    echo "IP=$IP" > "${CONFPATH}external.boxnet_altip_${NAME}.conf" 
    echo "Updated network object $FW ruleset to $IP via API " >> $LOG 2>&1

    done
    

if [ "$SMTPNOTIFICATION" = true ]; then
  mailclt -f "$FROM" -r "$TO" -s "$SUBJECT" -m "$SMTPSERVER" -t $LOG > /dev/null 2>&1
fi

exit 0
