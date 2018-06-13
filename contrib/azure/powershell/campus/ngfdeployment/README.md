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


## Required Azure PowerShell Version
Use Azure PowerShell 4.3.1 or newer. If in doubt always use the latest Azure PowerShell version.
Check the PowerShell version with the following command:
```
Get-Module -ListAvailable -Name AzureRM -Refresh
```
## Step-by-Step Instructions on Barracuda Campus
Fill in the variables at the top of the script to match your setup. For more in depth instructions follow the instructions on Barracuda Campus.
For more information, see [Barracuda Campus](https://campus.barracuda.com/product/nextgenfirewallf/doc/53248363/how-to-deploy-an-f-series-firewall-in-microsoft-azure-using-powershell-and-arm/).

For deployments in regions without Marketplace first complete the instructions to upload a VHD into Azure for use with ARM and then use this script.
https://campus.barracuda.com/product/cloudgenfirewall/doc/53248361/how-to-upload-azure-vhd-images-for-user-defined-images-using-arm/

For WAF deployments this script will create the load balancer as well as access and management rules through the load balancer. 

##### DISCLAIMER: ALL OF THE SOURCE CODE ON THIS REPOSITORY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL BARRACUDA BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOURCE CODE. #####
