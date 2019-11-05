#!/bin/bash
for i in "$@"
do
case $i in
    -r=*|--rulename=*)
    RULENAME="${i#*=}"
    ;;
    -s=*|--secondaryip=*)
    SECONDARYIP="${i#*=}"
    ;;
    -p=*|--primaryip=*)
    PRIMARYIP="${i#*=}"
    ;;
	-m=*|--mgmtip=*)
    MGMTIP="${i#*=}"
    ;;
	--default)
    DEFAULT=YES
    ;;
    *)
            # unknown option 
    ;;
esac
done

if test -n "${MGMTIP}"
    then
	python2.7 /root/azurescript/vpncheck.py -r "${RULENAME}" -p "${PRIMARYIP}" -s "${SECONDARYIP}" -m "${MGMTIP}"
fi
