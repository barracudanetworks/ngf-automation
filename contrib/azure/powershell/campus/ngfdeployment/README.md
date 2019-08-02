# Deploy a Barracuda CloudGen Firewall F via Azure PowerShell Script
For most advanced networking features in Microsoft Azure, such as multiple network interfaces or user images, deploy the NextGen Firewall F via this PowerShell script. This script can also be used for deployment in regions without Marketplace.
The NextGen Control Center for Microsoft Azure is deployed just like the NextGen Firewall F except that it is limited to one network interface. 
To organize the resources in the cloud, it is recommend to use multiple resource groups. This way, it is possible to separate storage from networking and the VMs. You can also assign different permissions in Azure to control access to the resources. We recommend using at least two different resource groups:

* **Networking resource group** – Contains the Azure Virtual network. For HA clusters, the load balancer would also be placed in this resource group. You can also add VNET to VNET Azure VPN Gateways to this group. For stand-alone NGF VMs, you can also add the UDR route table to this resource group.
* **Firewall resource group** – Contains the firewall VM as well as NICs, public IP addresses, and, if needed, the UDR routing table for HA clusters.
* **(optional) Storage resource group** – Contains the storage accounts holding user-defined images and OS disk images for the VMs. This is not needed if managed disks are used.

# Deploy a Barracuda CloudGen Firewall WAF via Azure PowerShell Script
For most advanced networking features in Microsoft Azure, such as multiple network interfaces or user images, deploy the WAF via this PowerShell script. This script can also be used for deployment in regions without Marketplace.
To organize the resources in the cloud, it is recommend to use multiple resource groups. This way, it is possible to separate storage from networking and the VMs. You can also assign different permissions in Azure to control access to the resources. We recommend using at least two different resource groups:

* **Networking resource group** – Contains the Azure Virtual network. For HA clusters, the load balancer would also be placed in this resource group. You can also add VNET to VNET Azure VPN Gateways to this group. For stand-alone NGF VMs, you can also add the UDR route table to this resource group.
* **Firewall resource group** – Contains the firewall VM as well as NICs, public IP addresses, and, if needed, the UDR routing table for HA clusters.
* **(optional) Storage resource group** – Contains the storage accounts holding user-defined images and OS disk images for the VMs. This is not needed if managed disks are used.
* **Load Balancers** - will create Basic ELB for any WAF deployment and defaults to using Standard LB setup for firewalls
* **Multiple Data Disks** - allows FW's to be deployed with multiple data disks for increased storage and better IOPS performance
* **Network Security Groups** - creates simple NSG's for the FW or WAF

New Az module script ngf_deploy_az.ps1 will also deploy;
* **Cluster of CGF's** Including a HA pair with Standard LB's or multiple none clustered nodes behind the Load balancers. 
* **Multi-NIC ** - can deploy dual NIC CGF clusters with External and Internal LB
* **Availability Zones ** - can deploy into Availabilty Zones instead of Availabilty Sets
* **Accelerated Networking ** - can deploy VM's with accelerated networking enabled (version 8.0 releases and above)


## Required Azure PowerShell Version
There are two versions of this script, ngf_deploy_azurerm.ps1 for Powershell AzureRM modules, and ngf_deploy_az.ps1 for the newest Az module.
Use Azure PowerShell AzureRM 4.3.1 or newer or Az 2.2.0 or newer. If in doubt always use the latest Azure PowerShell version.
Check the PowerShell versions with the following commands:
```
Get-InstalledModule -Name AzureRM,Az
```
## Step-by-Step Instructions on Barracuda Campus
Fill in the variables at the top of the script to match your setup. For more in depth instructions follow the instructions on Barracuda Campus.
For more information, see [Barracuda Campus](https://campus.barracuda.com/product/nextgenfirewallf/doc/53248363/how-to-deploy-an-f-series-firewall-in-microsoft-azure-using-powershell-and-arm/).

## Az Module script differences
This script contains the parameters but can be called via another powershell script and treated like a function if desired. New parameters introduced by this script are;
- quantity -use this to define the number of CGF's or WAF's to be deployed. If you deploy two CGF's as per default they will be clustered automatically
- xclr8net - set to $false by default, set to $true to enable Accelerated Networking support
- lbSku - defaults now to Standard for any CFG deploy.
- avZone - set this to $true to deploy into AZ's'

Example calling it from within Powershell deploying the latest version in a dual NIC, Availabilty Zone, 2 node cluster.
	.\DeploymentPowerShell-Newmodule.ps1 -location "East US 2" -SubnetName "External" -SubnetName2 "Internal" -vmAvZone $true -ResourceGroupName "GA-EUS2-PWSHTEST1" `
 -vnetName "MY-VNET-NAME" -vnetResourceGroupName "MY-VNET-RESOURCEGROUPNAME" -xcl8Net $true -vmSize "Standard_DS2_v2" -vmSuffix 'MY-CGF' 

For deployments in regions without Marketplace first complete the instructions to upload a VHD into Azure for use with ARM and then use this script.
https://campus.barracuda.com/product/cloudgenfirewall/doc/53248361/how-to-upload-azure-vhd-images-for-user-defined-images-using-arm/

If the $lbSku variable is set to Standard then the CGF will deploy an internal and external Standard LB with basic access rules.

For WAF deployments this script will create the load balancer as well as access and management rules through the load balancer. 

##### DISCLAIMER: ALL OF THE SOURCE CODE ON THIS REPOSITORY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL BARRACUDA BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOURCE CODE. #####
