#################################################
# Modify the variables below
#################################################
# Enable verbose output and stop on error
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

# Location
$location = '' # E.g., West Europe

#Set the below to true to use managed disks or false to define your own.
$useManagedDisks = $true
#Also answer these
$PlatformFaultDomainCount = 2
$PlatformUpdateDomainCount = 2


# Storage Account Name complete these if you are not using managed disks
$storageAccountName = 'your_storage_account_name'
$storageAccountContainerName = 'your_blob_container_name'
$storageAccountResourceGroupName = 'your_storage_resource_group_name'

# Enter to use a User Defined VM image E.g., https://docstorage0.blob.core.windows.net/vhds/GWAY-6.2.0-216-Azure.vhd
# Leave empty to use the latest image from the Azure Marketplace
$customSourceImageUri = ''

# Select the License type
$vmLicenseType = 'hourly' # set this to 'hourly' to use the PAYG image, or 'byol' for the BYOL image

# Set the product type
$vmProductType ='barracuda-ng-firewall' # Use 'barracuda-ng-firewall' for F-Series Firewall or 'barracuda-ng-cc' for the NextGen Control Center or 'waf' if you wish to deploy a Web Application Firewall.

#Run the following to see the other image offers available.
#Get-AzureRmVMImageOffer -PublisherName "barracudanetworks" -Location "$($location)"


# VNET
$vnetName = 'your_virtual_network_name'
$vnetResourceGroupName = 'your_virtual_network_resource_group_name'

# Availability Set
# always set a availability set in case you want to deploy a second firewall for HA later.
$vmAvSetName ='NGF-AV-SET'

# Static IP address for the NIC
$nic1InternalIP = '' # always make sure this IP address is available or leave this variable empty to use the next available IP address

# Barracuda NextGen Firewall F VM settings
$NGFResourceGroupName = 'NGF_RG'
$rootPassword = 'NGf1r3wall$$'
$vmSuffix = 'NGF' #
$vmName = '{0}' -f $vmSuffix
$vmSize = 'Standard_A3'
$nicName = '{0}-NIC1' -f $vmSuffix
$nicName2 = '{0}-NIC2' -f $vmSuffix
$ipName = '{0}-IP' -f $vmSuffix
$domName = $vmSuffix.ToLower()
$diskName = 'osdisk'
$datadiskName1 = 'datadisk1'
$datadiskName2 = 'datadisk2'
$datadiskName3 = 'datadisk3'
# size of a single data disk size in GB. Multiply the size by the number of disks to received the total disk size of the RAID device
$datadisksize = 40
$storageType = ""


#############################################
#
# No configuration variables past this point
#
#############################################

Write-Host 'Starting Deployment - this may take a while'

# Authenticate
Login-AzureRmAccount

# Create the ResourceGroup for the Barracuda NextGen Firewall F
Write-Verbose ('Creating NGF Resource Group {0}' -f $NGFresourceGroupName)
New-AzureRmResourceGroup -Name $NGFresourceGroupName -Location $location -ErrorAction Stop


# Use existing storage account
$storageAccount = Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $storageAccountResourceGroupName

# Use an existing Virtual Network
Write-Verbose ('Using VNET {0} in Resource Group {1}' -f $vnetNamem,$vnetResourceGroupName )
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroupName

#If the useManagedDisks variable is set to $true then this will switch the command required.
if($useManagedDisks){
#Use this version to build with a managed disk
    $vmAvSet = New-AzureRmAvailabilitySet -Name $vmAvSetName -ResourceGroupName $NGFResourceGroupName -Location $location -Managed -WarningAction SilentlyContinue -PlatformFaultDomainCount $PlatformFaultDomainCount -PlatformUpdateDomainCount $PlatformUpdateDomainCount
}else{
# Create Availability Set if it does not exist yet
    $vmAvSet = New-AzureRmAvailabilitySet -Name $vmAvSetName -ResourceGroupName $NGFResourceGroupName -Location $location  -WarningAction SilentlyContinue
}

# Create the NIC and new Public IP

#Doesn't deploy the PIP IP if this is a WAF image.
if($vmProductType -ne "waf"){
    Write-Verbose 'Creating Public IP'
    $pip = New-AzureRmPublicIpAddress -ResourceGroupName $NGFresourceGroupName -Location $location -Name $ipName -DomainNameLabel $domName -AllocationMethod Static
}

Write-Verbose 'Creating NIC'
if ($nic1InternalIP -eq '')
{
    $nic = New-AzureRmNetworkInterface -ResourceGroupName $NGFresourceGroupName -Location $location -Name $nicName -PublicIpAddressId $pip.Id -SubnetId $vnet.Subnets[0].Id -EnableIPForwarding
}
else
{
    $nic = New-AzureRmNetworkInterface -ResourceGroupName $NGFresourceGroupName -Location $location -Name $nicName -PrivateIpAddress $nic1InternalIP -PublicIpAddressId $pip.Id -SubnetId $vnet.Subnets[0].Id -EnableIPForwarding
}

# NIC #2 - OPTIONAL
#$nic2 = New-AzureRmNetworkInterface -ResourceGroupName $NGFresourceGroupName -Location $location -Name $nicName2 -SubnetId $vnet.Subnets[1].Id -EnableIPForwarding -PrivateIpAddress $nic2IP


# Create the VM Configuration

Write-Verbose 'Creating NGF VM Configuration'

$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $vmAvSet.Id

# Set root password
$cred = New-Object PSCredential 'placeholderusername', ($rootPassword | ConvertTo-SecureString -AsPlainText -Force)
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -ErrorAction Stop

# Add primary network interface
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id -ErrorAction Stop -Primary

# Add NIC #2
#$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic2.Id -ErrorAction Stop

#If there are no managed disks requested then generates the URI's
if(!$useManagedDisks){
    # generate the name for the OS disk
    $osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $diskName

    # generate URI for the datadisks
    $dataDiskUri1 = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $datadiskName1
    $dataDiskUri2 = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $datadiskName2
    $dataDiskUri3 = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $datadiskName3

}



# Specify the OS disk with user image
if ($customSourceImageUri -eq '')
{
    Write-Verbose 'Using lasted image from the Azure Marketplace'
    $vm.Plan = @{'name'= $vmLicenseType; 'publisher'= 'barracudanetworks'; 'product' = $vmProductType}
    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName 'barracudanetworks' -Skus $vmLicenseType -Offer $vmProductType -Version 'latest' -ErrorAction Stop

    #
    if($useManagedDisks){
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -StorageAccountType $storageType -DiskSizeInGB 128 -CreateOption FromImage
    }else{
        # Set the name and storage for the OS Disk image.
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
    }
}
else
{
    Write-Verbose ('Using user defined image {0}' -f $customSourceImageUri)
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $customSourceImageUri -Linux
}


if($useManagedDisks -and $vmProductType -ne "waf"){
  # add the datadisks
    Write-Verbose 'Adding data disks'
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName1 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 1
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName2 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 2
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName3 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 3
}else{
    # add the datadisks
    Write-Verbose 'Adding data disks'
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName1 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 1 -VhdUri $dataDiskUri1
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName2 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 2 -VhdUri $dataDiskUri2
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName3 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 3 -VhdUri $dataDiskUri3
}
Write-Verbose 'Creating Barracuda NextGen Firewall F VM. This can take a while ....'
$result = New-AzureRmVM -ResourceGroupName $NGFresourceGroupName -Location $location -VM $vm


if($result.IsSuccessStatusCode -eq 'True') {
   $result
   Write-Host ('Barracuda NextGen Firewall F VM ''{0}'' was successfully deployed.  Connect to the firewall at {2} with the username: root and password: {1}' -f $vmName, $rootPassword, (Get-AzureRmPublicIpAddress -ResourceGroupName $NGFResourceGroupName -Name $ipName).IpAddress)
} else {
    Write-Host ('Deployment Failed. {0}' -f $result.ReasonPhrase)
}
