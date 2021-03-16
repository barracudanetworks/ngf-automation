#!/bin/bash
##############################################################################################################
#  ____                                      _       
# | __ )  __ _ _ __ _ __ __ _  ___ _   _  __| | __ _ 
# |  _ \ / _` | `__| `__/ _` |/ __| | | |/ _` |/ _` |
# | |_) | (_| | |  | | | (_| | (__| |_| | (_| | (_| |
# |____/ \__,_|_|  |_|  \__,_|\___|\__,_|\__,_|\__,_|
#                                                    
#!/bin/bash
# Azure Public IP failover script.
#
# AUTHOR: Gemma Allen (gallen@barracuda.com)
# LASTEDIT: 2021-03-03
#
##############################################################################################################
# This script is to be triggered by the Virtual Server and runs upon start up of the Virtual Server

for i in "$@"
do
case $i in
    -i=*|--ipconfig=*)
    IPCONFIG="${i#*=}"
    ;;
    -p=*|--pip=*)
    PIP="${i#*=}"
    ;;
    -s=*|--secondpip=*)
    SECONDPIP="${i#*=}"
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option 
    ;;
esac
done

# Local logging adapt the LOGDIR variable to the directory where script is installed.
TODAY=`date +"%Y-%m-%d %T"`
LOGDIR="/phion0/logs"
LOG="$LOGDIR/ipshifting-$TODAY.log"

# Email Notification
SMTPNOTIFICATION=true
SMTPSERVER="[EMAIL-SERVER]"
FROM="[EMAIL-FROM]"
TO="[EMAIL-TO]"
SUBJECT="IPSHIFTING Result - CloudGen Firewall F-Series - $TODAY"

echo "-------------------------------------------------------------------------" 
  echo " IP Shifting script for Barracuda CloudGen Firewall F-Series" 
  echo " Date: $TODAY" 
  echo " see $LOG for more details"
  echo "-------------------------------------------------------------------------" 

echo "$TODAY - Supplied PIP : $PIP" >> $LOG 2>&1
echo "$TODAY - Supplied IPCONFIG: $IPCONFIG" >> $LOG 2>&1

if [ ! -z "$PIP" ];  
then
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

    #Get the Name of the other VM
    OTHER=$(az vm list --query "[?name!='$VM'].{name:name}" -o tsv)
    echo "$TODAY - Get other VM Name $OTHER" >> $LOG 2>&1
    #Get the NIC ID of the other VM
    OTHERID=$(az vm show --name $OTHER -g $RG --query 'networkProfile.networkInterfaces[0].id' -o tsv)
    echo "$TODAY - Get the other VM NIC ID $OTHERID" >> $LOG 2>&1
    #Get the other NIC Name
    OTHERNIC=$(az network nic show --ids $OTHERID --query "name" -o tsv)

    echo "$TODAY - Get the other VM NIC : $OTHERNIC" >> $LOG 2>&1

  RESULT=$(az network public-ip list --query "[?ends_with(to_string(ipConfiguration.id), '$IPCONFIG')] | [?contains(to_string(ipConfiguration.id), '$NIC')].name" -o tsv)

  while [ "$RESULT" != "$PIP" ]
    do
        #removed the IP from the otehr boxes NIC 
        #az network nic ip-config update --name $IPCONFIG --nic-name $NIC --resource-group $RG --remove "publicIpAddress"
        az network nic ip-config update --name $IPCONFIG --nic-name $OTHERNIC --resource-group $RG --remove "publicIpAddress"

        
        #az network nic ip-config update --name $IPCONFIG --nic-name $OTHERNIC --resource-group $RG --public-ip-address $PIP
        az network nic ip-config update --name $IPCONFIG --nic-name $NIC --resource-group $RG --public-ip-address $PIP
        
        #if a second PIP is provided then attempts to switch that onto the no longer active box.
        if [ ! -z "$PIP" ];  
        then
           az network nic ip-config update --name $IPCONFIG --nic-name $OTHERNIC --resource-group $RG --public-ip-address $SECONDPIP
           SECONDRESULT=$(az network public-ip list --query "[?ends_with(to_string(ipConfiguration.id), '$IPCONFIG')] | [?contains(to_string(ipConfiguration.id), '$OTHERNIC')].name" -o tsv)
          echo "$TODAY - Get current PIP $SECONDRESULT" >> $LOG 2>&1
        fi

        #Validate that IP moved. by searching for what PIP is allocated to this NIC
        RESULT=$(az network public-ip list --query "[?ends_with(to_string(ipConfiguration.id), '$IPCONFIG')] | [?contains(to_string(ipConfiguration.id), '$NIC')].name" -o tsv)


        echo "$TODAY - Get current PIP $RESULT" >> $LOG 2>&1
       
      #retry in 30 seconds
      sleep 30
      #breaks out after 3 minutes
      COUNTER=$(expr $COUNTER + 1)
      if [ $COUNTER -eq 5 ]
      then
        break
      fi

    done

  if [ "$RESULT" == "$PIP" ];
    then
      echo "$TODAY - SUCCESS" >> $LOG 2>&1
    else
      echo "$TODAY - FAILURE" >> $LOG 2>&1
  fi
    
fi

if [ "$SMTPNOTIFICATION" = true ]; then
  mailclt -f "$FROM" -r "$TO" -s "$SUBJECT" -m "$SMTPSERVER" -t $LOG > /dev/null 2>&1
fi

exit 0