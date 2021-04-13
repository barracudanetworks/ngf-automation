#!/bin/bash
##############################################################################################################
#  ____                                      _       
# | __ )  __ _ _ __ _ __ __ _  ___ _   _  __| | __ _ 
# |  _ \ / _` | `__| `__/ _` |/ __| | | |/ _` |/ _` |
# | |_) | (_| | |  | | | (_| | (__| |_| | (_| | (_| |
# |____/ \__,_|_|  |_|  \__,_|\___|\__,_|\__,_|\__,_|
#                                                    
#!/bin/bash
# Multiple Public IP failover script.
#
# AUTHOR: Gemma Allen (gallen@barracuda.com)
# LASTEDIT: 27 July 2020
#
##############################################################################################################

for i in "$@"
do
case $i in
    -s=*|--server=*)
    SERVER="${i#*=}"
    ;;
    -f=*|--fwservice=*)
    FWSERVICE="${i#*=}"
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option 
    ;;
esac
done

#Below is a completed example.
#/opt/aws/bin/aws ec2 associate-address --instance-id $(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id) --allocation-id eipalloc-1a1a1a1as1a1 --allow-reassociation --private-ip-address 192.168.2.10 > /dev/null 2>&1

#These commands will move the elastic IP's across between the firewall IP's, you need a command for each elastic IP you wish to move.

/opt/aws/bin/aws ec2 associate-address --instance-id $(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id)  --allocation-id <youreipallocid1> --allow-reassociation --private-ip-address yoursecondaryprivateip1 > /dev/null 2>&1

/opt/aws/bin/aws ec2 associate-address --instance-id $(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id) --allocation-id <youreipallocid2> --allow-reassociation --private-ip-address yoursecondaryprivateip1 > /dev/null 2>&1

/opt/aws/bin/aws ec2 associate-address --instance-id $(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id) --allocation-id <youreipallocid3> --allow-reassociation --private-ip-address yoursecondaryprivateip1 > /dev/null 2>&1

#Add further IP's here by copying the above command and editing the -allocation-id <value> and the --private-ip-address <value> 


#Writes a log of the IP allocations
/opt/aws/bin/aws ec2 describe-addresses --filters "Name=instance-id,Values=$(/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id)" > /tmp/ipalloc_output
 
#Trigger the script to update the dynamic network object files
python2.7 /customscripts/multiip_object_rewrite.py -i ${SERVER} -s ${FWSERVICE}

exit 0
