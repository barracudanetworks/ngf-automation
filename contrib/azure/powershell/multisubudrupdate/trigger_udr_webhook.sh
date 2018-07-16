#!/bin/bash
for i in "$@"
do
case $i in
    -u=*|--url=*)
    URL="${i#*=}"
    ;;
    -s=*|--service=*)
    SERVICE="${i#*=}"
    ;;
    -n=*|--nic=*)
    NIC="${i#*=}"
    ;;
	--default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
done

if test -n "${URL}"
    then
        
	if test -n "${SERVICE}"
		then
			if test -n "${NIC}" 
				then
					#echo URL= ${URL}
					#echo SERVICE = ${SERVICE}
					#echo NIC = ${NIC}
					python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -s ${SERVICE} -i ${NIC}
				else
					#echo URL= ${URL}
					#echo SERVICE = ${SERVICE}
					python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -s ${SERVICE} 
			fi
		else
			if test -n "${NIC}"
				then	
					python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -i ${NIC}
				#echo URL= ${URL}
				#echo NIC = ${NIC}
			else
				python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL}
				#echo URL= ${URL}
			fi
	fi	
fi
