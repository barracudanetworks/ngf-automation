#!/bin/sh
##############################################################################################################
#  ____                                      _       
# | __ )  __ _ _ __ _ __ __ _  ___ _   _  __| | __ _ 
# |  _ \ / _` | `__| `__/ _` |/ __| | | |/ _` |/ _` |
# | |_) | (_| | |  | | | (_| | (__| |_| | (_| | (_| |
# |____/ \__,_|_|  |_|  \__,_|\___|\__,_|\__,_|\__,_|
#                                                    
# Backup script for the Barracuda CloudGen Firewall F-Series.
# The backup destination is an Azure blob storage or AWS S3 bucket
#
# AUTHOR: Gemma Allen (gallen@barracuda.com)
# LASTEDIT: 20 April 2020
#
##############################################################################################################
# Updated to use managed identity and azure cli
##############################################################################################################
#accept variable in calling.
for i in "$@"
do
case $i in
    -b=*|--bucket=*)
    S3BUCKET="${i#*=}"
    ;;
    -s=*|--storageaccount=*)
    STORAGEACCOUNT="${i#*=}"
    ;;
    -c=*|--container=*)
    CONTAINER="${i#*=}"
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
TODAY=`date +"%Y-%m-%d"`
LOGDIR="/root/backup"
LOG="$LOGDIR/backup-$TODAY.log"

# Email Notification
SMTPNOTIFICATION=true
SMTPSERVER="[EMAIL-SERVER]"
FROM="[EMAIL-FROM]"
TO="[EMAIL-TO]"
SUBJECT="Backup CloudGen Firewall F-Series - $TODAY"

# Creating the log directory
if [ ! -d "$LOGDIR" ];
then
  echo
  echo "Creating local log directory ($LOG) on Barracuda CloudGen Firewall F-Series ..."
  mkdir -p $LOGDIR
fi

if [ ! -z "$S3BUCKET" ]; 
then
    echo "AWS"
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null`
    VM=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
fi

if [ ! -z "$STORAGEACCOUNT" ];  
then
    echo "AZURE"
    #authenticates to the CLI uisng the system identity
    #Get VM name
    VM=$(curl -sH Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2017-08-01&format=text")
    az login --identity >> $LOG 2>&1
    #SPID=$(az resource list -n $vm --query [*].identity.principalId --out tsv)
fi


# Backup filename
FILENAME=$VM`date +%Y_%m_%d_%H_%M`.par

{
  echo "-------------------------------------------------------------------------" 
  echo " Backup script for Barracuda CloudGen Firewall F-Series" 
  echo " Date: $TODAY"
  echo
  echo "-------------------------------------------------------------------------" 
  echo " Creating the backup files"
  if [ -d /opt/phion/config/configroot/ ];
  then
    cd /opt/phion/config/configroot/
    /opt/phion/bin/phionar cdl "$LOGDIR/$FILENAME" *
  fi
  echo


if [ ! -z "$S3BUCKET" ]; 
then
	echo "-------------------------------------------------------------------------"
	echo " Transfer to AWS cloud storage account: $S3BUCKET/$CONTAINER" 
	echo

 fi    

if [ ! -z "$STORAGEACCOUNT" ];  
then
	echo "-------------------------------------------------------------------------"
	echo " Transfer to Azure cloud storage account: $STORAGEACCOUNT/$CONTAINER" 
	echo 
    
fi



  if [ ! -z "$S3BUCKET" ]; 
  then
      /opt/aws/bin/aws s3 cp "$LOGDIR/$FILENAME" s3://$S3BUCKET/
  fi
  if [ ! -z "$STORAGEACCOUNT" ]; 
  then
      az storage blob upload --account-name $STORAGEACCOUNT --container $CONTAINER --file "$LOGDIR/$FILENAME" --name $FILENAME
  fi
  echo
  echo "-------------------------------------------------------------------------"
  echo " Clean up" 
  rm -f "$LOGDIR/$FILENAME"
  echo "-------------------------------------------------------------------------"
  echo " Done." 
  echo "-------------------------------------------------------------------------"
} >> $LOG 2>&1

if [ "$SMTPNOTIFICATION" = true ]; then
  mailclt -f "$FROM" -r "$TO" -s "$SUBJECT" -m "$SMTPSERVER" -t $LOG > /dev/null 2>&1
fi


exit 0