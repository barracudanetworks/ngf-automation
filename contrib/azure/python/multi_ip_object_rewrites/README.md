# Barracuda CloudGen Firewall: Updating dynamic objects with the IP aliases of the network interface. 

## Introduction
This project is intended to provide an example of how you can utilise scripts on the Barracuda CloudGen Firewall to update dynamic objects and multiple ipconfigs in Azure. In Azure you can have [multiple ip aliases attached to the NIC of a VM](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-multiple-ip-addresses-portal). 

In this project a python script on the CGF units is triggered upon starting the virtual server (e.g. on failover or boot time) to read the configuration and adapt the dynamic object with the correct ip alias of the active CGF unit. This allows for NAT behind an IP alias for outbound connections. In Azure outbound NAT is only possible to either the load balancer public IP when there are no public IP's on the VM NIC. If there are public IP's on the VM NIC these IP's will be used. To have more public IP's we can NAT behind IP aliases on the VM NIC.

## Components
Within this project you will find included a script files and a example configuration to import into the Barracuda CloudGen Firewall. 

1. ipconfig_failover.sh - gathers the local CGF information and updates the dynamic object files
2. network_object_template.conf - sample configuration object for a dynamic IP generated from file. 

## Workflow

- CGF Failover triggers running of ipconfig_failover.sh shell script
- ipconfig_failover.sh checks the IP configurations on the primary NIC of the firewall and assigns those IP's to network objects with matching names

## Installation

1.  First prepare the FW rules by pre-creating the dynamic objects, to allow you to create the right type take the project file 'network_object_template.conf' and
copy it into a text editor. For each ip Alias you created you will need to import an object per the below steps. 
	a) Search for the string "youripname" in the conf file, replace this text with the name of the Azure IP configuration you wish this to collect the address from.
	b) Once edited Select All into your clipboard
	c) Go to Forwarding Firewall Rules, Network Objects and right click and Paste
![CGF Network configuration Network Architecture](images/azureipconfig.png)
You should now have new object entry named after the ipconfiguration names used on the NIC in Azure. <b>It is critical that these share the same name!</b>

3. Now we prepare the scripts for failover, temporarily open SSH and on each CGF via SSH run: 
	`
	mkdir /root/azurescript
	`

To enable SSH access verify the following article on our [campus](https://campus.barracuda.com/product/cloudgenfirewall/doc/73719781/how-to-enable-ssh-root-access-for-public-cloud-firewalls/?sl=AWUAaK0wBDp2IHciOf61&so=1) website. Password Authentication can be enabled by selecting Configuration Mode > Switch to Advanced and then opening the Advanced Settings. Make sure to add a BoxACL to limit access to SSH from specific IP's or remove access to SSH access after the changes.

2. Copy the ipconfig_failover.sh onto the CGF firewall into the customscript folder. Do this for both CGF's!

3. Run the following commands to set the permissions
	`
	chmod 755 /root/customscript/ipconfig_failover.sh
	`
4. On the CGF go into Infrastructure Services > Control and enable Advanced Configuration mode, the in /root/customscript/ipconfig_failover.sh add to the Startup Script add;
	`	/root/customscript/ipconfig_failover.sh  `

6. Once complete you can test this by failing over, you can view the dynamic objects and their IP's in Firewall > Forwarding Firewall Rules > Networks > Dynamic 

![CGF Network configuration Network Architecture](images/dynamicobject.png)

7. Finally to use these for an outbound NAT, create a Connection Object referencing this new Single IP dynamic object and use that in the ruleset.

![CGF Network configuration Network Architecture](images/connectionobject.png)
![CGF Network configuration Network Architecture](images/firewallrule.png)

## Troubleshooting
This script will write logs into /phion0/logs/ipconfig_switch.log


##### DISCLAIMER: ALL OF THE SOURCE CODE ON THIS REPOSITORY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL BARRACUDA BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOURCE CODE. #####
