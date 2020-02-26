# Deploy a Barracuda CloudGen Firewall F via Azure PowerShell Script
For most advanced networking features in Microsoft Azure, such as multiple network interfaces or user images, deploy the CloudGen Firewall F via this PowerShell script. This script can also be used for deployment in regions without Marketplace.
The CloudGen Control Center for Microsoft Azure is deployed just like the CloudGen Firewall F except that it is limited to one network interface. 
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
* **Clustering** Including a HA pair with Standard LB's or multiple none clustered nodes behind the Load balancers. 
* **Multi-NIC** - can deploy dual NIC CGF clusters with External and Internal LB
* **Availability Zones** - can deploy into Availabilty Zones instead of Availabilty Sets
* **Accelerated Networking** - can deploy VM's with accelerated networking enabled (version 8.0 releases and above)


## Required Azure PowerShell Version
There are two versions of this script, ngf_deploy_azurerm.ps1 for Powershell AzureRM modules, and ngf_deploy_az.ps1 for the newest Az module.
The Az module has expanded features with regards to deployment options for the advanced users. 
Use Azure PowerShell AzureRM 4.3.1 or newer or Az 2.2.0 or newer. If in doubt always use the latest Azure PowerShell version.
Check the PowerShell versions with the following commands:
```
Get-InstalledModule -Name AzureRM,Az
```
# Step-by-Step Instructions on Barracuda Campus
Fill in the variables at the top of the script to match your setup. For more in depth instructions follow the instructions on Barracuda Campus.
For more information, see [Barracuda Campus](https://campus.barracuda.com/product/CloudGenfirewallf/doc/53248363/how-to-deploy-an-f-series-firewall-in-microsoft-azure-using-powershell-and-arm/).

# New Az Module script differences
This script contains the parameters but can be called via another powershell script and treated like a function if desired. New parameters introduced by this script are;
#Parameters
This script contains a number of default values which help simplify the options available below you will see the parameters explained. To deploy a standard HA cluster using the lastest abilities you just need to provide the compulsory parameters
Everything else is optional and you can use to customise to suit your deployment requirement. 

### Compulsory
$location - define the location in which you are building
$rootPassword - provide a password string
$vmPrefix - provide a name for the VM a number will be appended, eg. MYNAME-1
$vnetname - provide the name of the vnet
$vnetResourceGroupName - provide the resource group of the vnet
$SubnetName - provide the name of the subnet the devices will go in
$vmLicenseType - either byol or hourly 
$vmProductType - a choice of barracuda-ng-firewall, waf, barracuda-cc


### Quantity
$quantity - defaults to 2 for a HA setup, but can be 1 or greater as required. Beyond 2 and the Firewalls are not clustered and require another method to manage their configs such a CC or RESTAPI

### High Availbilty controls from Azure
$vmAvZone - this defaults to true and unless you provide an AVSET name will be used. 
$vmAvSetName - provide this value and it will be used
$PlatformFaultDomainCount - use this numeric value to determine the AV set fault domain
$PlatformUpdateDomainCount - use this numeric value to determine the AV set fault domain

### Performance and Load Balancer features
$acceleratedNetworking - defaults to true but will disable on 1 core units
$lbSku - defaults to standard for Firewall deployments

### Non-Managed disk deployments must provide the following values.
$storageAccountName - name of the storage account
$storageAccountContainerName - container name to use within that storage account
$storageAccountResourceGroupName - resource group the storage account belongs too. 

### Custom Versions or Images
To deploy using custom images or a specific version use the following parameters - if you need to customise the existing values you can lookup versions using
Get-AzVMImage -Location $location -PublisherName "barracudanetworks" -Offer $vmProductType -Skus $vmLicenseType

$cgfVersion - defaults to latest but use the options to select an alternative
$wafVersion - defaults to latest but use the options to select an alternative
$customSourceImageUri - provide a https path to a suitable vhd to build from
$customImage - provide the name of a custom image you have created

### Additional Disks for High IOPS
Use when high logging requirements expected or WANOpt is used. Add multiple data disks to increase IOPS
$datadisksize - provide the size in GB of the data disk, eg. 256 
$datadiskqty - provide the number of data disks to be stripped together for max IOPS

### Multiple NIC deployments
$SubnetNameNic2 - provide the name of a second subnet if you wish to deploy using 2 NICs
Custom IP deployments - the script will by default allocate the first available IP's in the provided subnets to itself and the Internal LB for Active/Passive deployments this script
will allow you to manually define the IP's if you wish. Do NOT use these with deployments beyond 2 hosts 
$ilbIp - sets the private IP for the first subnets internal LB
$cgf1nic1InternalIP - sets the private IP for the first firewalls first NIC
$cgf2nic1InternalIP - sets the private IP for the second firewalls first NIC
$ilb2Ip - sets the private IP for the second subnets internal LB
$cgf1nic2InternalIP - sets the private IP for the first firewalls second NIC
$cgf2nic2InternalIP - sets the private IP for the second firewalls second NIC

### Misc
$enableREST - defaults to true and enables the REST API
$storageType - defaults to Premium_LRS but can be adjusted as desired.

### Control Center Integration
To have the deployment collect the config from Control Center 
$ccSecret - secret key used by CC to authorise this request
$ccIP - public or private IP of the CC reachable by this deployment
$ccRangeId - control Center range that the config should be collected from
$ccClusterName - control Center Cluster name that the config should be collected from. 

Example calling it from within Powershell deploying the latest version in a dual NIC, Availabilty Zone, 2 node cluster.
```
	.\cgf_deploy_az.ps1 -location "East US 2" -SubnetName "External" -SubnetName2 "Internal" -vmAvZone $true -ResourceGroupName "MY-PWSH-RG" `
 -vnetName "MY-VNET" -vnetResourceGroupName "MY-VNET-RESOURCEGROUPNAME" -xcl8Net $true -vmSize "Standard_DS2_v2" -vmSuffix 'MY-CGF' 
```

Example calling it from within powershell deploying 3 firewalls behind a LB with multiple data disks and a select version.
```
..\cgf_deploy_az.ps1 -location "East US 2" -vmProductType barracuda-ng-firewall -vmLicenseType hourly -vnetName MY-VNET -vnetResourceGroupName GMY-VNET-RESOURCEGROUPNAMEMY-VNET-RESOURCEGROUPNAME `
-SubnetName mysubnet -ResourceGroupName "MY-PWSH-RG" -vmPrefix "GA-PWHS-CGFMY-CGF" -vmAvSetName "GA-PWSH-AVSET" -quantity 3 -datadisksize 50 -datadiskQty 2
```

Example building a WAF cluster

```
..\cgf_deploy_az.ps1  -location "East US 2" -vmProductType barracuda-ng-firewall -vmLicenseType byol -vnetName MY-VNET -vnetResourceGroupName MY-VNET-RESOURCEGROUPNAME `
-SubnetName mysubnet -ResourceGroupName "MY-PWSH-RG" -vmPrefix "MY-WAF" -vmAvZone 
```

Example building a single Control Center

```
..\cgf_deploy_az.ps1  -location "East US 2" -vmProductType barracuda-ng-firewall -vmLicenseType byol -vnetName MY-VNET -vnetResourceGroupName MY-VNET-RESOURCEGROUPNAME `
-SubnetName mysubnet -ResourceGroupName "MY-PWSH-RG" -vmPrefix "MY-CC" -vmAvZone 
```

For deployments in regions without Marketplace first complete the instructions to upload a VHD into Azure for use with ARM and then use this script.
https://campus.barracuda.com/product/cloudgenfirewall/doc/53248361/how-to-upload-azure-vhd-images-for-user-defined-images-using-arm/

If the $lbSku variable is set to Standard then the CGF will deploy an internal and external Standard LB with basic access rules.

For WAF deployments this script will create the load balancer as well as access and management rules through the load balancer. 

##### DISCLAIMER: ALL OF THE SOURCE CODE ON THIS REPOSITORY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL BARRACUDA BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOURCE CODE. #####
