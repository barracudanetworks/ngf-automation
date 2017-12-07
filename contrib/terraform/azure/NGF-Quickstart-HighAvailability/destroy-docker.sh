#!/bin/bash
cat << "EOF"
##############################################################################################################
#  ____                                      _       
# | __ )  __ _ _ __ _ __ __ _  ___ _   _  __| | __ _ 
# |  _ \ / _` | `__| `__/ _` |/ __| | | |/ _` |/ _` |
# | |_) | (_| | |  | | | (_| | (__| |_| | (_| | (_| |
# |____/ \__,_|_|  |_|  \__,_|\___|\__,_|\__,_|\__,_|
#                                                    
# Deployment of the Barracuda NextGen Firewall F-Series in High Availability using Terraform
#
##############################################################################################################
EOF

# Stop running when command returns error
set -e

SECRET="/ssh/cudalab/secrets.tfvars"
STATE="/data/state/terraform.tfstate"

echo "==> Terraform destroy"
echo ""
docker run --rm -itv $PWD:/data -v $PWD/terraform-run:/.terraform/ -v ~/.ssh:/ssh/ jvhoof/ansible-docker \
    terraform destroy --state="$STATE" -var-file="$SECRET" /data/terraform
