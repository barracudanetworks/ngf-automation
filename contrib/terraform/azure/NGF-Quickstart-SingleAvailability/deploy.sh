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

STATE="state/terraform.tfstate"

# Input prefix 
echo -n "Enter prefix: "
stty_orig=`stty -g` # save original terminal setting.
read prefix         # read the password
stty $stty_orig     # restore terminal setting.

# Input password 
echo -n "Enter password: "
stty_orig=`stty -g` # save original terminal setting.
stty -echo          # turn-off echoing.
read password         # read the password
stty $stty_orig     # restore terminal setting.

# Stop running when command returns error
set -e

echo ""
echo "==> Terraform init: $1"
echo ""
terraform init -var "prefix=$prefix" -var "password=$password" $1

echo ""
echo "==> Terraform plan"
echo ""
terraform plan -state="$STATE" -var "prefix=$prefix" -var "password=$password" $1

echo ""
echo "==> Terraform apply"
echo ""
terraform apply -state="$STATE" -var "prefix=$prefix" -var "password=$password" $1