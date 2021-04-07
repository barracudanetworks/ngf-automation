

# Backup Scripts for Barracuda CloudGen Firewall F-Series and CloudGen Control Center

## Introduction
This script is a example of using the Azure CLI embedded on all v8 and above Firewalls alongside managed identity to allow the firewall to move public IP's between members of a cluster on failover. 

## Prequisits
The CloudGen Firewalls must be configured with managed identities, the firewall identities must have Contributor permission over the resource group containing the network interfaces and public IP addresses of the firewall. 
The Firewall managed identities must have write access over the subnet in the virtual network in which they are located.


## Installation 
<ol>
    <li>It is presumed your Firewalls were built using managed system identifies or a user assigned identity, if not you can configure these following the instructions [here](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-portal-windows-vm) </li>
    <li>Temporarily enable SSH to install the scripts.
    <li>Create a directory for the scripts <code> mkdir /customscript/ </code></li>
    <li>Copy the script to the firewall into <code>cd /customscript/<filename></code></li>
    <li>Verify and make sure the script is executable: <code># chmod 755 ipshifting.sh</code></li>
    <li>If you are using Azure, in the Azure portal go to the storage account created to receives these backups, go into IAM and assign the Contributor role to the Virtual Machine roles for the Firewalls ![Assign Role ](images/assignrole.png)</li>
    <li>If you are in AWS, in the AWS portal assign the instances sufficient permissions to write to the S3 storage account 
    <li>Trigger the script providing the name of the public IP and ipconfiguration for example <code> ./customscript/ipshifting.sh -p="publicipname" -i="ipconfig" </code> </li>
    <li>If need you can configure the script to email out, please edit the SMTP varibles directly in the script to do this.</li>
    <li>Trigger the script to occur upon failover on the firewall that is starting.
        <ol>
        <li>Go to Configuration Tree > Infrastructure Services > Control</Li>
        <li>Go to Custom Scripts and Lock the config
        <li>Enter into the Start Script your details <code>/root/customscript/ipshifting.sh -i="ipconfig" -p="publicIPname"</code>
        </ol>
        </li>
    <li> Optionally, if you wish to block a service while the script runs add <code> -b="SERVERNAME SERVICENAME" </code> e.g <code> -b="CSC VPN"</code>. The script will automatically hold the service blocked for 5 minutes. 
</ol>

With this done the script will trigger upon failover and move an IP address between hosts. To move Multiple IP addresses trigger multiple scripts with different public IP and ipconfig values.

If you wish to switch IP's between Active and passive boxes it is a case of configuring the Stop Script to try to claim the other IP. If the box stops suddenly then this may not occur.


### Troubleshooting
If the script doesn't make changes as expected the try running elements manually, in particular test the line below which moves IP's
`az network nic ip-config update --name $IPCONFIG --nic-name $OTHERNIC --resource-group $RG --remove "publicIpAddress"`

If you receive this error then you do not have sufficient permission on the subnet into which the Firewalls NIC's are attached. You must edit the IAM permissions so that you have read/write permission to this subnet or if you cannot create custom roles, Contributor rights to the Virtual Network.

![Assign Role ](images/permissionserror.png)