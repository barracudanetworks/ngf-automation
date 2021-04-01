#!/bin/sh

# By default the python script will use the default server (S1) and service (NGFW) names. In case 
# you have different names you can adapt them below using the -i and -s arguments.
python2.7 /root/azurescript/multiip_object_rewrite.py -i S1 -s NGFW