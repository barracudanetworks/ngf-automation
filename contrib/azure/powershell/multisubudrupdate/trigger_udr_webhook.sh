if test -n "$1"
    then
        python2.7 /root/azurescript/ngf_call_udr_webhook.py -u $1 
	if test -n "$2"
		then	
			python2.7 /root/azurescript/ngf_call_udr_webhook.py -u $1 -i $2
	fi
fi


#The below example is for when running MultiNIC and needed to change UDR for additional IP's'
#python2.7 /root/azurescript/ngf_call_udr_webhook.py -u <url to webhook> -i <NAMEOFADDITIONALIP>

#The below example is for when running under control center with non-default service names
#python2.7 /root/azurescript/ngf_call_udr_webhook.py -u <url to webhook> -s <NAMEOFS1_FWSERVICE>