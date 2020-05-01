#!/bin/bash
##############################################################################################################
#  ____                                      _       
# | __ )  __ _ _ __ _ __ __ _  ___ _   _  __| | __ _ 
# |  _ \ / _` | `__| `__/ _` |/ __| | | |/ _` |/ _` |
# | |_) | (_| | |  | | | (_| | (__| |_| | (_| | (_| |
# |____/ \__,_|_|  |_|  \__,_|\___|\__,_|\__,_|\__,_|
#                                                    
# Backup script for the Barracuda NextGen Control Center.
# The backup destination is an Azure Blob Storage Container.
#
# AUTHOR: Joeri Van Hoof (jvanhoof@barracuda.com)
# LASTEDIT: 06 November 2017
#
##############################################################################################################
# Based on this script: https://github.com/fabianfabian/blobize.sh/blob/master/blobize.sh
# Azure Storage Documentation: https://docs.microsoft.com/en-us/rest/api/storageservices/Authentication-for-the-Azure-Storage-Services?redirectedfrom=MSDN
##############################################################################################################

# Local logging adapt the LOGDIR variable to the directory where script is installed.
TODAY=`date +"%Y-%m-%d"`
LOGDIR="/root/backup"
LOG="$LOGDIR/backup-$TODAY.log"

# Email Notification
SMTPNOTIFICATION=true
SMTPSERVER="[EMAIL-SERVER]"
FROM="[EMAIL-FROM]"
TO="[EMAIL-TO]"
SUBJECT="Backup NextGen Firewall F-Series - $TODAY"

# Backup filename
FILENAME=CC-tree_`date +%Y_%m_%d_%H_%M`.par
FILENAMEGZ="$FILENAME.gz"
FILENAME2=CC-box_`date +%Y_%m_%d_%H_%M`.par
FILENAMEGZ2="$FILENAME2.gz"

# Creating the log directory
if [ ! -d "$LOGDIR" ];
then
  echo
  echo "Creating local log directory ($LOG) on Barracuda CloudGen Firewall Control Central F-Series ..."
  mkdir -p $LOGDIR
fi

# Azure storage credentials
# Shared Access Signature, get it from the Azure Portal, starts with '?sv=', not the full URL.
SAS_TOKEN="[Shared Access Signature token]"
# Storage Account Name
AZURE_STORAGE_ACCOUNT="[Storage Account]"
# Blob container name, must be created already in the Azure portal
BLOB_CONTAINER="[Blob Container]"

urlencode_grouped_case () {
  string=$1; format=; set --
  while
    literal=${string%%[!-._~0-9A-Za-z]*}
    case "$literal" in
      ?*)
        format=$format%s
        set -- "$@" "$literal"
        string=${string#$literal};;
    esac
    case "$string" in
      "") false;;
    esac
  do
    tail=${string#?}
    head=${string%$tail}
    format=$format%%%02x
    set -- "$@" "'$head"
    string=$tail
  done
  printf "$format\\n" "$@"
}

{
  echo "-------------------------------------------------------------------------" 
  echo " Backup script for Barracuda NextGen Control Center" 
  echo " Date: $TODAY"
  echo
  echo "-------------------------------------------------------------------------" 
  echo " Creating the backup files"
  if [ -d /opt/phion/maintree/ ];
  then
    cd /opt/phion/maintree/
    /opt/phion/bin/phionar cdl "$LOGDIR/$FILENAME" *
    gzip "$LOGDIR/$FILENAME"   
  fi
  if [ -d /opt/phion/config/configroot ];
  then
    cd /opt/phion/config/configroot/
    /opt/phion/bin/phionar cdl "$LOGDIR/$FILENAME2" *
    gzip "$LOGDIR/$FILENAME2"   
  fi
  echo

  echo "-------------------------------------------------------------------------"
  echo " Transfer to Azure Storage Account $AZURE_STORAGE_ACCOUNT in blob $BLOB_CONTAINER" 
  echo
  MIME_TYPE=$(file -b --mime-type "$LOGDIR/$FILENAMEGZ")
  BLOB_NAME_URL=$(urlencode_grouped_case "$FILENAMEGZ")
  DATE_UTC=$(date -u)
  /usr/bin/curl -X PUT -T "$LOGDIR/$FILENAMEGZ" -H "x-ms-date: $DATE_UTC" -H "Content-Type: $MIME_TYPE" -H "x-ms-blob-type: BlockBlob" \
		--silent --write-out "%{http_code} : Posted backup file: $FILENAME\n" \
		"https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$BLOB_CONTAINER/$BLOB_NAME_URL$SAS_TOKEN" 

  MIME_TYPE=$(file -b --mime-type "$LOGDIR/$FILENAME2GZ")
  BLOB_NAME_URL=$(urlencode_grouped_case "$FILENAME2GZ")
  DATE_UTC=$(date -u)
  /usr/bin/curl -X PUT -T "$LOGDIR/$FILENAMEGZ2" -H "x-ms-date: $DATE_UTC" -H "Content-Type: $MIME_TYPE" -H "x-ms-blob-type: BlockBlob" \
		--silent --write-out "%{http_code} : Posted backup file: $FILENAME2\n" \
		"https://$AZURE_STORAGE_ACCOUNT.blob.core.windows.net/$BLOB_CONTAINER/$BLOB_NAME_URL$SAS_TOKEN" 

  echo
  echo "-------------------------------------------------------------------------"
  echo " Clean up" 
  rm -f "$LOGDIR/$FILENAME"
  rm -f "$LOGDIR/$FILENAME2"
  echo "-------------------------------------------------------------------------"
  echo " Done." 
  echo "-------------------------------------------------------------------------"
} >> $LOG 2>&1

if [ "$SMTPNOTIFICATION" = true ]; then
  mailclt -f "$FROM" -r "$TO" -s "$SUBJECT" -m "$SMTPSERVER" -t $LOG > /dev/null 2>&1
fi

exit 0