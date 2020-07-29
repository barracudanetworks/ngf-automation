#!/bin/bash
for i in "$@"
do
case $i in
    -t=*|--token=*)
    TOKEN="${i#*=}"
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option 
    ;;
esac
done

#The below example is to import Azure IP ranges into the Firewall
python2.7 /root/customscript/import_azure_ips.py --token ${TOKEN}
#for v8 provide the value --virtualserver "CSC"


#for Importing of office365 IP's 
#python2.7 /root/customscript/import_o365_ips.py --export-all