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

STATE="state/terraform.tfstate"

TF_INIT="terreaform-run"
if [ ! -d $TF_INIT ] 
then
    mkdir -p $TF_INIT
fi 

# Input password 
echo -n "Enter password: "
stty_orig=`stty -g` # save original terminal setting.
stty -echo          # turn-off echoing.
read password       # read the password
stty $stty_orig     # restore terminal setting.

# Stop running when command returns error
set -e

echo ""
echo "==> Terraform init"
echo ""
terraform init -var "password=$password" terraform/

echo ""
echo "==> Terraform plan"
echo ""
terraform plan -state="$STATE" -var "password=$password" terraform/

echo ""
echo "==> Terraform apply"
echo ""
terraform apply -state="$STATE" -var "password=$password" terraform/