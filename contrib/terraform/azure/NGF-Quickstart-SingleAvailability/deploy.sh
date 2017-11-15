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

SECRET="~/.ssh/secrets.tfvars"
STATE="/data/state/terraform.tfstate"

echo ""
echo "==> Terraform init"
echo ""
terraform init -var-file="$SECRET" 

echo ""
echo "==> Terraform plan"
echo ""
terraform plan -state="$STATE" -var-file="$SECRET"

echo ""
echo "==> Terraform apply"
echo ""
terraform apply -state="$STATE" -var-file="$SECRET"