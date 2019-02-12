#!/bin/bash
cat << "EOF"
##############################################################################################################
#  ____                                      _       
# | __ )  __ _ _ __ _ __ __ _  ___ _   _  __| | __ _ 
# |  _ \ / _` | `__| `__/ _` |/ __| | | |/ _` |/ _` |
# | |_) | (_| | |  | | | (_| | (__| |_| | (_| | (_| |
# |____/ \__,_|_|  |_|  \__,_|\___|\__,_|\__,_|\__,_|
#                                                    
# Deployment of the Barracuda NextGen Firewall F-Series in Single Availability using Terraform
#
##############################################################################################################
EOF

# Stop running when command returns error
set -e

SECRET="/ssh/cudalab/secrets.tfvars"
STATE="/data/state/terraform.tfstate"

TF_INIT="terreaform-run"
if [ ! -d $TF_INIT ] 
then
    mkdir -p $TF_INIT
fi 

echo ""
echo "==> Terraform init"
echo ""
docker run --rm -itv $PWD:/data -v $PWD/terraform-run:/.terraform/ -v ~/.ssh:/ssh/ jvhoof/ansible-docker terraform init -var-file="$SECRET" /data/terraform

echo ""
echo "==> Terraform plan"
echo ""
docker run --rm -itv $PWD:/data -v $PWD/terraform-run:/.terraform/ -v ~/.ssh:/ssh/ jvhoof/ansible-docker terraform plan -state="$STATE" -var-file="$SECRET" /data/terraform

echo ""
echo "==> Terraform apply"
echo ""
docker run --rm -itv $PWD:/data -v $PWD/terraform-run:/.terraform/ -v ~/.ssh:/ssh/ jvhoof/ansible-docker terraform apply -state="$STATE" -var-file="$SECRET" /data/terraform 