#################################################
# Modify the variables below to suit your environment and deployment.
# This script is intended to be used to deploy into an existing Virtual Network and Subnet.
#
#################################################
# Enable verbose output and stop on error
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

# Location
$location = '' # E.g., West Europe

#Set the below to true to use managed disks or false to define your own.
$useManagedDisks = $true
#If using managed disk this must be defined for the storage type e.g Standard_LRS, Premium_LRS, note older versions of powershell used StandardLRS or PremiumLRS

$storageType = "Premium_LRS"
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
$imageName = 'yourimagename'



# Set the product type - even if you are using a defined image so the script can deploy the correct additional components
# Use 'barracuda-ng-firewall' for F-Series Firewall or 'barracuda-ng-cc' for the NextGen Control Center or 'waf' if you wish to deploy a Web Application Firewall.
$vmProductType ='barracuda-ng-firewall' 

#Run the following to see the other image offers available.
#Get-AzureRmVMImageOffer -PublisherName "barracudanetworks" -Location "$($location)"

# Select the License type
$vmLicenseType = 'byol' # set this to 'hourly' to use the PAYG image, or 'byol' for the BYOL image

#Set the version to be deployed #latest
$vmVersion = 'latest'
#You can review the versions available using the below command
#Get-AzureRmVMImage -Location $location -PublisherName "barracudanetworks" -Offer $vmProductType -Skus $vmLicenseType


# VNET
$vnetName = 'your_virtual_network_name'
$vnetResourceGroupName = 'your_virtual_network_resource_group_name'
$SubnetName = 'subnetname'
#$SubnetNameNic2 = 'yoursecondsubnetname'

# Availability Set
# always set a availability set in case you want to deploy a second firewall for HA later.
$vmAvSetName ='youravsetname'

# Static IP address for the NIC
$nic1InternalIP = '' # always make sure this IP address is available or leave this variable empty to use the next available IP address
$nic2InternalIP = '' # always make sure this IP address is available or leave this variable empty to use the next available IP address

#Set the type of NIC and LB's used, either Basic or Standard for the new type any port LB for HA. 
#Basic is the correct value for WAF's, CGF's may use either Basic or Standard depending on failover requirements
$lbSku = "Basic"

# VM settings
#Provide the Resource Group Name you will deploy into
$ResourceGroupName = 'yourresourcegroupname'
$rootPassword = 'NGf1r3wall$$'
$vmSuffix = 'CGF' #
$vmName = '{0}' -f $vmSuffix
$vmSize = 'Standard_DS2_v2'
$nicName = '{0}-NIC1' -f $vmSuffix
#$nicName2 = '{0}-NIC2' -f $vmSuffix
$ipName = '{0}-IP' -f $vmSuffix
$domName = $vmSuffix.ToLower()
$lbName = '{0}-LB' -f $vmSuffix
$diskName = 'osdisk-{0}' -f (New-Guid)
#Uncomment the below lines if additional data disks are required by the CGF (WAF's don't need these)
#$datadiskName1 = 'datadisk1-{0}' -f (New-Guid)
#$datadiskName2 = 'datadisk2-{0}' -f (New-Guid)
#$datadiskName3 = 'datadisk3-{0}' -f (New-Guid)
# size of a single data disk size in GB. Multiply the size by the number of disks to received the total disk size of the RAID device
$datadisksize = 40



#############################################
#
# From this point the script will create the resources as determined by the variables completed above.
#
#############################################

Write-Host 'Starting Deployment - this may take a while'

# Authenticate
Login-AzureRmAccount

if(!(Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction SilentlyContinue)){
    # Create the ResourceGroup for the Barracuda NextGen Firewall F
    Write-Verbose ('Creating Resource Group {0}' -f $ResourceGroupName)
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction Stop
}else{
    Write-Verbose ('Deploying into Resource Group {0}' -f $ResourceGroupName)
}


if(!$useManagedDisks){
    # Use existing storage account
    $storageAccount = Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $storageAccountResourceGroupName
}else{
    if($customSourceImageUri){
        #Creates a reusable image to allow a managed disk instance to be deployed from Image. 
        $imageConfig = New-AzureRmImageConfig -Location $location
        $imageConfig = Set-AzureRmImageOsDisk -Image $imageConfig -OsState Generalized -OsType Linux -BlobUri $customSourceImageUri
        $image = New-AzureRmImage -ImageName $imageName -ResourceGroupName $ResourceGroupName -Image $imageConfig 
        
    }
}

# Use an existing Virtual Network
Write-Verbose ('Using VNET {0} in Resource Group {1}' -f $vnetName,$vnetResourceGroupName )
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroupName

#This will set the subnet ID based on the Subnet name suplied in the variables section
$SubnetId = ($vnet.Subnets | Where-Object -Property Name -EQ -Value $SubnetName).Id

if($nicName2){

    Write-Verbose ('Using {0} in VNET {1} for second NIC' -f $SubnetNameNic2,$vnetName )
	$SubnetIdNic2 = ($vnet.Subnets | Where-Object -Property Name -EQ -Value $SubnetNameNic2).Id

}

Write-Verbose 'Creating Availability Set'
if(!$useManagedDisks){
    # Create Availability Set if it does not exist yet
    $vmAvSet = New-AzureRmAvailabilitySet -Name $vmAvSetName -ResourceGroupName $ResourceGroupName -Location $location  -WarningAction SilentlyContinue

}else{
    #Use this version to build with a managed disk
    $vmAvSet = New-AzureRmAvailabilitySet -Name $vmAvSetName -ResourceGroupName $ResourceGroupName -Location $location -Managed -WarningAction SilentlyContinue -PlatformFaultDomainCount $PlatformFaultDomainCount -PlatformUpdateDomainCount $PlatformUpdateDomainCount

}

# Create the NIC and new Public IP

#For CGF's this script will deploy a PIP for initial management access, for WAF's this scrupt will setup a LB with inbound management permitted.
if($vmProductType -ne "waf"){
    Write-Verbose 'Creating Public IP'
    $pip = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location -Name $ipName -DomainNameLabel $domName -AllocationMethod Static -Sku $lbSku 

}else{
	#Deploy's a load balancer with the public IP assigned to it
    Write-Verbose 'Creating Public Load Balancer'
	$pip = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location -Name $ipName -DomainNameLabel $domName -AllocationMethod Static -Sku $lbSku
    
    #Defines the LB configuration, this creates basic inbound port 80 and 443 rules with a probe
	$Frontend = New-AzureRmLoadBalancerFrontendIpConfig -Name "$($lbName)-FrontendIP" -PublicIpAddressId $pip.Id 
	$Probe = New-AzureRmLoadBalancerProbeConfig -Name "$($lbName)-Probe" -Protocol Http -Port 8000 -RequestPath '/' -IntervalInSeconds 5 -ProbeCount 3 
	$BackendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "$($lbName)-BackendPool" 
	$lbRule1 = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -Protocol Tcp -FrontendPort 80 -BackendPort 80 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	$lbRule2 = New-AzureRmLoadBalancerRuleConfig -Name "HTTPS" -Protocol Tcp -FrontendPort 443 -BackendPort 443 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	$natRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "$($vmName)-Management" -FrontendIpConfigurationId $Frontend.Id -Protocol Tcp -FrontendPort 8001 -BackendPort 8000
	$natRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "$($vmName)-SecureManagement" -FrontendIpConfigurationId $Frontend.Id -Protocol Tcp -FrontendPort 8444 -BackendPort 8443 
	
    #Creates the LB.
    $lb = New-AzureRmLoadBalancer -Name $lbName -ResourceGroupName $ResourceGroupName -Location $location -Sku $lbSku -FrontendIpConfiguration $Frontend -BackendAddressPool $BackendPool -Probe $Probe -InboundNatRule $natRule1,$natRule2 -LoadBalancingRule $lbRule1,$lbRule2 

}


#Creates the NSG's
Write-Verbose 'Creating Network Security Groups'

if($vmProductType -ne "waf"){
#Creates NSG's for the CGF that allow the firewall to manage what inbound and outbound traffic is accepted
    $rule1 = New-AzureRmNetworkSecurityRuleConfig -Name "Allow_All_Inbound" -Protocol * -SourcePortRange * -DestinationPortRange * -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Inbound
    $rule2 = New-AzureRmNetworkSecurityRuleConfig -Name "Allow_All_Outbound" -Protocol * -SourcePortRange * -DestinationPortRange * -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Outbound
    $nsg = New-AzureRmNetworkSecurityGroup -Name "$vmName-NSG" -ResourceGroupName $ResourceGroupName -Location $location -SecurityRules $rule1,$rule2

}else{
#Creates NSG's for the WAF that limit inbound access to the default HTTP and HTTPS ports plus management access.
	$destinationAddressPrefix = ($vnet.Subnets | Where-Object -Property Name -EQ -Value $SubnetName).AddressPrefix

    $rule1 = New-AzureRmNetworkSecurityRuleConfig -Name "Allow_Inbound_HTTP" -Protocol Tcp -SourcePortRange * -DestinationPortRange 80 -SourceAddressPrefix * -DestinationAddressPrefix "$($destinationAddressPrefix)" -Access Allow -Priority 100 -Direction Inbound
    $rule2 = New-AzureRmNetworkSecurityRuleConfig -Name "Allow_Inbound_HTTPS" -Protocol Tcp -SourcePortRange * -DestinationPortRange 443 -SourceAddressPrefix * -DestinationAddressPrefix "$($destinationAddressPrefix)" -Access Allow -Priority 101 -Direction Inbound
    $rule3 = New-AzureRmNetworkSecurityRuleConfig -Name "Allow_Inbound_Management" -Protocol Tcp -SourcePortRange * -DestinationPortRange 8000 -SourceAddressPrefix * -DestinationAddressPrefix "$($destinationAddressPrefix)" -Access Allow -Priority 102 -Direction Inbound
    $rule4 = New-AzureRmNetworkSecurityRuleConfig -Name "Allow_Inbound_SecureManagement" -Protocol Tcp -SourcePortRange * -DestinationPortRange 8443 -SourceAddressPrefix * -DestinationAddressPrefix "$($destinationAddressPrefix)" -Access Allow -Priority 103 -Direction Inbound
    $nsg = New-AzureRmNetworkSecurityGroup -Name "$vmName-NSG" -ResourceGroupName $ResourceGroupName -Location $location -SecurityRules $rule1,$rule2,$rule3,$rule4

}


#This section deploys the network interfaces required depending on WAF or NGF and static or DHCP IP values.
Write-Verbose 'Creating Network Interfaces'
if ($nic1InternalIP -eq '')
{
	if($vmProductType -eq "waf"){
		#When deploying a WAF adds the interface into the Load Balancers Backend pool and NAT Rules
		$nic = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId -LoadBalancerBackendAddressPoolId $BackendPool.Id -LoadBalancerInboundNatRuleId $natRule1.Id, $natRule2.Id -NetworkSecurityGroupId $nsg.id
	}else{
		$nic = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -PublicIpAddressId $pip.Id -SubnetId $SubnetId -EnableIPForwarding -NetworkSecurityGroupId $nsg.id  
	}
    
}
else
{
	
	if($vmProductType -eq "waf"){
		#When deploying a WAF adds the interface into the Load Balancers Backend pool and NAT Rules
		$nic = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -PrivateIpAddress $nic1InternalIP -SubnetId $SubnetId -LoadBalancerBackendAddressPoolId $BackendPool.Id -LoadBalancerInboundNatRuleId $natRule1.Id, $natRule2.Id -NetworkSecurityGroupId $nsg.id
	}else{
		$nic = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -PrivateIpAddress $nic1InternalIP -PublicIpAddressId $pip.Id -SubnetId $SubnetId -EnableIPForwarding -NetworkSecurityGroupId $nsg.id 
	}
    
}
#If the second nic name has been uncommented in the variables this will create a second NIC
if($nicName2){
    if ($nic2InternalIP -eq ''){
        $nic2 = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $SubnetIdNic2  -EnableIPForwarding 
    }else{
	    $nic2 = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $SubnetIdNic2 -EnableIPForwarding -PrivateIpAddress $nic2InternalIP
    }
}

# Create the VM Configuration

Write-Verbose 'Creating NGF VM Configuration'

$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $vmAvSet.Id

# Set root password
$cred = New-Object PSCredential 'placeholderusername', ($rootPassword | ConvertTo-SecureString -AsPlainText -Force)
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -ErrorAction Stop

# Add primary network interface
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id -ErrorAction Stop -Primary

# If the second NIC was created earlier this will be associated to the VM here.
if($nic2){
	$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic2.Id -ErrorAction Stop 
}
#If there are no managed disks requested then generates the URI's

if(!$useManagedDisks){
    # generate the name for the OS disk
    $osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $diskName

    if($datadiskName1 -or $datadiskName2 -or $datadiskName3){
        # generate URI for the datadisks
        $dataDiskUri1 = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $datadiskName1
        $dataDiskUri2 = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $datadiskName2
        $dataDiskUri3 = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $datadiskName3
    }
}



# Specify the OS disk with user image
if ($customSourceImageUri -eq '')
{
    Write-Verbose 'Using lastest image from the Azure Marketplace'
    $vm.Plan = @{'name'= $vmLicenseType; 'publisher'= 'barracudanetworks'; 'product' = $vmProductType}
    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName 'barracudanetworks' -Skus $vmLicenseType -Offer $vmProductType -Version $vmVersion -ErrorAction Stop

    
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
    if(!$useManagedDisks){
        # Set the name and storage for the OS Disk image.
        $vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $customSourceImageUri -Linux   
    }else{
         $image.StorageProfile.OsDisk.StorageAccountType = $storageType
         $vm =  Set-AzureRmVMSourceImage -VM $vm -Id $image.Id
    }
}


if($useManagedDisks -and $vmProductType -ne "waf" -and $datadiskName1){
  # add the datadisks
    Write-Verbose 'Adding data disks'
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName1 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 1
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName2 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 2
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName3 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 3
}elseif($vmProductType -ne "waf" -and $datadiskName1){
    # add the datadisks
    Write-Verbose 'Adding data disks'
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName1 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 1 -VhdUri $dataDiskUri1
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName2 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 2 -VhdUri $dataDiskUri2
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name $datadiskName3 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun 3 -VhdUri $dataDiskUri3
}



Write-Verbose 'Creating Barracuda Cloud Gen Firewall VM. This can take a while ....'
$result = New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vm

if($result.IsSuccessStatusCode -eq 'True') {
   $result
    if($vmProductType -eq 'waf'){
        Write-Host ('Barracuda CGF WAF VM ''{0}'' was successfully deployed.  Connect to the firewall at http://{2}:8001 with the username: admin and password: {1}' -f $vmName, $rootPassword, (Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $ipName).IpAddress)
    }else{
        Write-Host ('Barracuda CGF Firewall VM ''{0}'' was successfully deployed.  Connect to the firewall at {2} with the username: root or and password: {1}' -f $vmName, $rootPassword, (Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $ipName).IpAddress)
    }
} else {
    Write-Host ('Deployment Failed. {0}' -f $result.ReasonPhrase)
}
