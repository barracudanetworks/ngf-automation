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
	-v=*|--vnet=*)
    VNET="${i#*=}"
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
					if test -n "${VNET}"
					then
						python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -s ${SERVICE} -i ${NIC} -n ${VNET}
					else
						python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -s ${SERVICE} -i ${NIC}
					fi
				else
					#echo URL= ${URL}
					#echo SERVICE = ${SERVICE}
					if test -n "${VNET}"
						then
						python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -s ${SERVICE}  -n ${VNET}
					else
						python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -s ${SERVICE} 
					fi
				fi
			fi
		else
			if test -n "${NIC}"
				then	
				#echo URL= ${URL}
				#echo NIC = ${NIC}
				if test -n "${VNET}"
					then
					python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -i ${NIC} -n ${VNET}
				else
					python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -i ${NIC}
				fi
			else
				if test -n "${VNET}"
					then
					python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL} -n ${VNET}
				else
					python2.7 /root/azurescript/ngf_call_udr_webhook.py -u ${URL}
				fi
				#echo URL= ${URL}
			fi
	fi	
fi
