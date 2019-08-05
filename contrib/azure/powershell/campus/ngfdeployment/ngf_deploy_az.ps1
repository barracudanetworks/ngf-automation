param(
#################################################
# You can either modify the default values of the parameters below and run this directly or pass them in via 
# ./ngf_deploy_az.ps1 -Location "East US 2"
# This script is intended to be used to deploy into an existing Virtual Network and Subnet.
#
#################################################
# Enable verbose output and stop on error
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$VerbosePreference = 'Continue',
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$ErrorActionPreference = 'Stop',
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$location, # E.g., West Europe

#Set the below to true to use managed disks or false to define your own.
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[bool]$useManagedDisks = $true,
#If using managed disk this must be defined for the storage type e.g Standard_LRS, Premium_LRS, note older versions of powershell used StandardLRS or PremiumLRS

[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$storageType = "Premium_LRS",
#Also answer these
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[int]$PlatformFaultDomainCount = 2,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[int]$PlatformUpdateDomainCount = 2,


# Storage Account Name complete these if you are not using managed disks
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$storageAccountName = 'your_storage_account_name',
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$storageAccountContainerName = 'your_blob_container_name',
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$storageAccountResourceGroupName = 'your_storage_resource_group_name',


# Enter to use a User Defined VM image E.g., https://docstorage0.blob.core.windows.net/vhds/GWAY-6.2.0-216-Azure.vhd
# Leave empty to use the latest image from the Azure Marketplace
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$customSourceImageUri,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$imageName,


# Set the product type - even if you are using a defined image so the script can deploy the correct additional components
# Use 'barracuda-ng-firewall' for F-Series Firewall or 'barracuda-ng-cc' for the NextGen Control Center or 'waf' if you wish to deploy a Web Application Firewall.
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[ValidateSet("barracuda-ng-firewall", "barracuda-ng-cc", "waf")]
[string]$vmProductType ='barracuda-ng-firewall' ,

#Run the following to see the other image offers available.
#Get-AzVMImageOffer -PublisherName "barracudanetworks" -Location "$($location)"

# Select the License type
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[ValidateSet("byol", "hourly")]
[string]$vmLicenseType = 'byol', # set this to 'hourly' to use the PAYG image, or 'byol' for the BYOL image

#Set the version to be deployed #latest
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[ValidateSet("latest", "7.2.3016101", "7.2.205701","7.2.112901","7.1.306101")]
[string]$vmVersion = "latest",
#You can review the versions available using the below command
#Get-AzVMImage -Location $location -PublisherName "MicrosoftWindowsServer" -Offer $vmProductType -Skus $vmLicenseType


# VNET
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$vnetName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$vnetResourceGroupName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$SubnetName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$SubnetNameNic2,

# Availability Set
# always set a availability set in case you want to deploy a second firewall for HA later.
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$vmAvSetName,
#To use availabilty zones provide a number for this VM to be built in
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[bool]$vmAvZone=$false,

# Static IP address for the NIC
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$nic1InternalIP = '', # always make sure this IP address is available or leave this variable empty to use the next available IP address
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$nic2InternalIP = '', # always make sure this IP address is available or leave this variable empty to use the next available IP address

#Set the type of NIC and LB's used, either Basic or Standard for the new type any port LB for HA. 
#Basic is the correct value for WAF's, CGF's may use either Basic or Standard depending on failover requirements
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$lbSku = "Standard",
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[bool]$xcl8Net=$false,
# VM settings
#Provide the Resource Group Name you will deploy into
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$ResourceGroupName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$rootPassword = 'NGf1r3wall$$',
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$vmSuffix, #,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[ValidateSet("Standard_DS1_v2", "Standard_DS2_v2", "Standard_DS3_v2","Standard_DS4_v2")]
[string]$vmSize = 'Standard_DS1_v2',
#Set data disk size and qty
# size of a single data disk size in GB. Multiply the size by the number of disks to received the total disk size of the RAID device
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[int]$datadisksize = 50,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[int]$datadiskQty = 0,

#Set this to 2 to build a cluster, 1 for standalone or 3+ for Active\Active designs
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[int]$quantity = 2
)

# Set root password
$cred = New-Object PSCredential 'placeholderusername', ($rootPassword | ConvertTo-SecureString -AsPlainText -Force)
#The remaining variables are automatically assigned based on the number of the qty this box is. You can create there definitions here. 
#The values $vmNum and $diskNum will be replaced in the loop with the appropriate number.
$vmNamedef = {'{0}-{1}' -f $vmSuffix,$vmNum}
$nicNamedef = {'{0}-NIC1' -f $vmName}
if($SubnetNameNic2){$nicName2def = {'{0}-NIC2' -f $vmName}}
$ipNamedef = {'{0}-IP' -f $vmName}
$lbNamedef = {'{0}-ELB' -f $vmName}
$diskNamedef = {'osdisk-{0}' -f (New-Guid)}
$datadiskNameDef = {'datadisk{0}-{1}-{2}' -f $vmName,$diskNum,(New-Guid)}
#ilbName only used when SKU is Standard
$ilbName = '{0}-ILB' -f $vmSuffix
$ilb2Name = '{0}-ILB-2' -f $vmSuffix
$elbName = '{0}-ELB' -f $vmSuffix
$nsgName = '{0}-NSG' -f $vmSuffix

#IP Addresses - the script if clustering will attempt to allocate the IP's automatically and will by default use the first 3 IP's in the subnet. If you don't want this fill in the below values.
#$ilbIp=""
#$cgf1nic1InternalIP=""
#$cgf2nic1InternalIP=""
#$ilb2Ip=""
#$cgf1nic2InternalIP=""
#$cgf2nic2InternalIP=""


$moduleversion = (Get-InstalledModule -Name "Az").Version
if(!$moduleversion){
    if(Get-InstalledModule -Name "AzureRM"){ Write-Host "This script is for the Az module. But you seem to have the AzureRM installed. Please use the other script"}
}else{
    Write-Verbose "Running Script for Az module version $($moduleversion.ToString())"
}

#############################################
#
# From this point the script will create the resources as determined by the variables completed above.
#
#############################################

Write-Host "Logging into Azure"
if($xcl8Net){
    Write-Host "Accelerated Networking enabled, VM deployment size $($vmSize), if this is not compatible deployment will fail!"

}

# Authenticate
Connect-AzAccount

Write-Host 'Starting Deployment - this may take a while'
if(!(Get-AzResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction SilentlyContinue)){
    # Create the ResourceGroup for the Barracuda NextGen Firewall F
    Write-Verbose ('Creating Resource Group {0}' -f $ResourceGroupName)
    New-AzResourceGroup -Name $ResourceGroupName -Location $location -ErrorAction Stop
}else{
    Write-Verbose ('Deploying into Resource Group {0}' -f $ResourceGroupName)
}


if(!$useManagedDisks){
    # Use existing storage account
    $storageAccount = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $storageAccountResourceGroupName
}else{
    if($customSourceImageUri){
        #Creates a reusable image to allow a managed disk instance to be deployed from Image. 
        $imageConfig = New-AzImageConfig -Location $location
        $imageConfig = Set-AzImageOsDisk -Image $imageConfig -OsState Generalized -OsType Linux -BlobUri $customSourceImageUri
        $image = New-AzImage -ImageName $imageName -ResourceGroupName $ResourceGroupName -Image $imageConfig 
        
    }
}

# Use an existing Virtual Network
Write-Verbose ('Using VNET {0} in Resource Group {1}' -f $vnetName,$vnetResourceGroupName )
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroupName

#This will set the subnet ID based on the Subnet name suplied in the variables section
$SubnetId = ($vnet.Subnets | Where-Object -Property Name -EQ -Value $SubnetName).Id
$subnetRange = ($vnet.Subnets | Where-Object -Property Name -EQ -Value $SubnetName).AddressPrefix

if($SubnetNameNic2){

    Write-Verbose ('Using {0} in VNET {1} for second NIC' -f $SubnetNameNic2,$vnetName )
	$Subnet2Id = ($vnet.Subnets | Where-Object -Property Name -EQ -Value $SubnetNameNic2).Id
    $subnet2Range = ($vnet.Subnets | Where-Object -Property Name -EQ -Value $SubnetNameNic2).AddressPrefix
}


#If creating a cluster e.g quantity 2 for CGF
if($quantity -eq 2 -and $vmProductType -ne "waf"){
    [string]$SubnetRange = $SubnetRange
    $gatewayIP = '{0}.{1}.{2}.{3}' -f $subnetRange.Split('.')[0],$subnetRange.Split('.')[1],$subnetRange.Split('.')[2],([int]$subnetRange.Split('.')[3].Split("/")[0]+1)
    if(!$ilbIp){$ilbIp = '{0}.{1}.{2}.{3}' -f $subnetRange.Split('.')[0],$subnetRange.Split('.')[1],$subnetRange.Split('.')[2],([int]$subnetRange.Split('.')[3].Split("/")[0]+4)}
    if(!$cgf1nic1InternalIP){$cgf1nic1InternalIP = '{0}.{1}.{2}.{3}' -f $subnetRange.Split('.')[0],$subnetRange.Split('.')[1],$subnetRange.Split('.')[2],([int]$subnetRange.Split('.')[3].Split("/")[0]+5)}
    if(!$cgf2nic1InternalIP){$cgf2nic1InternalIP = '{0}.{1}.{2}.{3}' -f $subnetRange.Split('.')[0],$subnetRange.Split('.')[1],$subnetRange.Split('.')[2],([int]$subnetRange.Split('.')[3].Split("/")[0]+6)}
    if($subnet2Range){
        [string]$Subnet2Range = $Subnet2Range
        if(!$ilb2Ip){$ilb2Ip = '{0}.{1}.{2}.{3}' -f $subnet2Range.Split('.')[0],$subnet2Range.Split('.')[1],$subnet2Range.Split('.')[2],([int]$subnet2Range.Split('.')[3].Split("/")[0]+4)}
        if(!$cgf1nic2InternalIP){$cgf1nic2InternalIP = '{0}.{1}.{2}.{3}' -f $subnet2Range.Split('.')[0],$subnet2Range.Split('.')[1],$subnet2Range.Split('.')[2],([int]$subnet2Range.Split('.')[3].Split("/")[0]+5)}
        if(!$cgf2nic2InternalIP){$cgf2nic2InternalIP = '{0}.{1}.{2}.{3}' -f $subnet2Range.Split('.')[0],$subnet2Range.Split('.')[1],$subnet2Range.Split('.')[2],([int]$subnet2Range.Split('.')[3].Split("/")[0]+6)}
    }

    #CustomData used to cluster Firewalls, don't edit unless you know what to do.
    $cgfCustomData1 = "#!/bin/bash`n`n/opb/cloud-setmip $($cgf1nic1InternalIP) $($subnetRange.Split("/")[1]) $($gatewayIP) `necho '$($rootPassword)' | /opb/create-dha -s S1 -c -o $($cgf2nic1InternalIP) -n $($subnetRange.Split("/")[1]) -g $($gatewayIP)`n"
    $cgfCustomData2 = "'`n'"
}


Write-Verbose 'Creating Availability Set'
if(!$vmAvZone){
    if(!$useManagedDisks){
        # Create Availability Set if it does not exist yet
        $vmAvSet = New-AzAvailabilitySet -Name $vmAvSetName -ResourceGroupName $ResourceGroupName -Location $location -Sku Classic  -WarningAction SilentlyContinue
    }else{
        #Use this version to build with a managed disk
        $vmAvSet = New-AzAvailabilitySet -Name $vmAvSetName -ResourceGroupName $ResourceGroupName -Location $location -Sku Aligned -WarningAction SilentlyContinue -PlatformFaultDomainCount $PlatformFaultDomainCount -PlatformUpdateDomainCount $PlatformUpdateDomainCount
    }
}else{
    Write-Host "Using Availability Zones"
}

#This will deploy the public IP's and load balancers for CGF and WAF
if($vmProductType -ne "waf"){
    Write-Verbose 'Creating Load Balancer'
    
    $lbpip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location -Name "$($elbName)-FrontendIP" -AllocationMethod Static -Sku $lbSku 
    
    $Frontend = New-AzLoadBalancerFrontendIpConfig -Name "$($elbName)-FrontendIP" -PublicIpAddressId $lbpip.Id
    $Probe = New-AzLoadBalancerProbeConfig -Name "$($elbName)-Probe" -Protocol TCP -Port 65000 -IntervalInSeconds 5 -ProbeCount 3 
	$BackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "$($elbName)-BackendPool" 
    $lbRule1 = New-AzLoadBalancerRuleConfig -Name "TINA-TCP" -Protocol Tcp -FrontendPort 691 -BackendPort 691 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	$lbRule2 = New-AzLoadBalancerRuleConfig -Name "TINA-UDP" -Protocol Udp -FrontendPort 691 -BackendPort 691 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	$lbRule3 = New-AzLoadBalancerRuleConfig -Name "IPSEC-500" -Protocol Udp -FrontendPort 500 -BackendPort 500 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	$lbRule4 = New-AzLoadBalancerRuleConfig -Name "IPSEC-4500" -Protocol Udp -FrontendPort 4500 -BackendPort 4500 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	
    #Creates the LBs
    $elb = New-AzLoadBalancer -Name $elbName -ResourceGroupName $ResourceGroupName -Location $location -Sku $lbSku -FrontendIpConfiguration $Frontend -BackendAddressPool $BackendPool -Probe $Probe -LoadBalancingRule $lbRule1,$lbRule2,$lbRule3,$lbRule4
  
    if($lbSku -eq "Standard"){
        if($ilb2Ip){
            $Frontend = New-AzLoadBalancerFrontendIpConfig -Name "$($ilb2Name)-FrontendIP" -SubnetId $Subnet2Id -PrivateIpAddress $ilb2IP
        }else{
            $Frontend = New-AzLoadBalancerFrontendIpConfig -Name "$($ilbName)-FrontendIP" -SubnetId $SubnetId -PrivateIpAddress $ilbIP
        }
		
        $intBackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "$($ilbName)-BackendPool"
        $Probe = New-AzLoadBalancerProbeConfig -Name "$($ilbName)-Probe" -Protocol TCP -Port 65000 -IntervalInSeconds 5 -ProbeCount 3
        
	    $lbRule5 = New-AzLoadBalancerRuleConfig -Name "HAPortsRule" -Protocol All -FrontendPort 0 -BackendPort 0 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $intBackendPool.Id  -ProbeId $Probe.Id
        $ilb = New-AzLoadBalancer -Name "$($ilbName)" -ResourceGroupName $ResourceGroupName -Location $location -Sku $lbSku -FrontendIpConfiguration $Frontend -BackendAddressPool $intBackendPool -Probe $Probe -LoadBalancingRule $lbRule5 
      
       
        
     
    }
}else{
	#Deploy's a load balancer with the public IP assigned to it
    Write-Verbose 'Creating Public Load Balancer'
	$pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location -Name $ipName -DomainNameLabel $domName -AllocationMethod Static -Sku $lbSku 
    
    #Defines the LB configuration, this creates basic inbound port 80 and 443 rules with a probe
	$Frontend = New-AzLoadBalancerFrontendIpConfig -Name "$($elbName)-FrontendIP" -PublicIpAddressId $pip.Id 
	$Probe = New-AzLoadBalancerProbeConfig -Name "$($elbName)-Probe" -Protocol Http -Port 8000 -RequestPath '/' -IntervalInSeconds 5 -ProbeCount 3 
	$BackendPool = New-AzLoadBalancerBackendAddressPoolConfig -Name "$($elbName)-BackendPool" 
	$lbRule1 = New-AzLoadBalancerRuleConfig -Name "HTTP" -Protocol Tcp -FrontendPort 80 -BackendPort 80 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	$lbRule2 = New-AzLoadBalancerRuleConfig -Name "HTTPS" -Protocol Tcp -FrontendPort 443 -BackendPort 443 -FrontendIpConfigurationId $Frontend.Id -BackendAddressPoolId $BackendPool.Id  -ProbeId $Probe.Id
	$natRule1 = New-AzLoadBalancerInboundNatRuleConfig -Name "$($vmName)-Management" -FrontendIpConfigurationId $Frontend.Id -Protocol Tcp -FrontendPort 8001 -BackendPort 8000
	$natRule2 = New-AzLoadBalancerInboundNatRuleConfig -Name "$($vmName)-SecureManagement" -FrontendIpConfigurationId $Frontend.Id -Protocol Tcp -FrontendPort 8444 -BackendPort 8443 
	
    #Creates the LBs
    $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $ResourceGroupName -Location $location -Sku $lbSku -FrontendIpConfiguration $Frontend -BackendAddressPool $BackendPool -Probe $Probe -InboundNatRule $natRule1,$natRule2 -LoadBalancingRule $lbRule1,$lbRule2 

}


#Creates the NSG's
Write-Verbose 'Creating Network Security Groups'

if($vmProductType -ne "waf"){
#Creates NSG's for the CGF that allow the firewall to manage what inbound and outbound traffic is accepted Any Any is used as otherwise protocols like ICMP cannot pass
    $rule1 = New-AzNetworkSecurityRuleConfig -Name "Block_Inbound_SSH" -Protocol Tcp -SourcePortRange * -DestinationPortRange 22 -SourceAddressPrefix Internet -DestinationAddressPrefix * -Access Deny -Priority 100 -Direction Inbound
    $rule2 = New-AzNetworkSecurityRuleConfig -Name "Allow_All_Inbound" -Protocol * -SourcePortRange * -DestinationPortRange * -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 110 -Direction Inbound
    $rule3 = New-AzNetworkSecurityRuleConfig -Name "Allow_All_Outbound" -Protocol * -SourcePortRange * -DestinationPortRange * -SourceAddressPrefix * -DestinationAddressPrefix * -Access Allow -Priority 100 -Direction Outbound
    $nsg = New-AzNetworkSecurityGroup -Name "$nsgName-NSG" -ResourceGroupName $ResourceGroupName -Location $location -SecurityRules $rule1,$rule2,$rule3

}else{
#Creates NSG's for the WAF that limit inbound access to the default HTTP and HTTPS ports plus management access.

    $rule1 = New-AzNetworkSecurityRuleConfig -Name "Allow_Inbound_HTTP" -Protocol Tcp -SourcePortRange * -DestinationPortRange 80 -SourceAddressPrefix * -DestinationAddressPrefix "$($SubnetRange)" -Access Allow -Priority 100 -Direction Inbound
    $rule2 = New-AzNetworkSecurityRuleConfig -Name "Allow_Inbound_HTTPS" -Protocol Tcp -SourcePortRange * -DestinationPortRange 443 -SourceAddressPrefix * -DestinationAddressPrefix "$($SubnetRange)" -Access Allow -Priority 101 -Direction Inbound
    $rule3 = New-AzNetworkSecurityRuleConfig -Name "Allow_Inbound_Management" -Protocol Tcp -SourcePortRange * -DestinationPortRange 8000 -SourceAddressPrefix * -DestinationAddressPrefix "$($SubnetRange)" -Access Allow -Priority 102 -Direction Inbound
    $rule4 = New-AzNetworkSecurityRuleConfig -Name "Allow_Inbound_SecureManagement" -Protocol Tcp -SourcePortRange * -DestinationPortRange 8443 -SourceAddressPrefix * -DestinationAddressPrefix "$($SubnetRange)" -Access Allow -Priority 103 -Direction Inbound
    $nsg = New-AzNetworkSecurityGroup -Name "$nsgName-NSG" -ResourceGroupName $ResourceGroupName -Location $location -SecurityRules $rule1,$rule2,$rule3,$rule4

}



#The items created above are shared, below are the unique VM and NIC creations.

For($vmNum=$quantity; $vmNum -ge 1; $vmNum--){

#Takes the naming convention definitions for use as variables inside the loop
$vmName = Invoke-Command $vmNamedef
$nicName = Invoke-Command $nicNamedef
$nicName2 = Invoke-Command $nicName2def
$ipName = Invoke-Command $ipNamedef
$diskName = Invoke-Command $diskNamedef

    if($vmProductType -ne "waf"){
        if($vmAvZone){
            $pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location -Name $ipName -AllocationMethod Static -Sku $lbSku -Zone $vmNum
        }else{
            $pip = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location -Name $ipName -AllocationMethod Static -Sku $lbSku
        }

    }

    #This section deploys the network interfaces required depending on WAF or NGF and static or DHCP IP values.
    Write-Verbose 'Creating Network Interfaces'
        if($vmProductType -eq "waf"){
		    #When deploying a WAF adds the interface into the Load Balancers Backend pool and NAT Rules
		    $nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId -LoadBalancerBackendAddressPoolId $BackendPool.Id -LoadBalancerInboundNatRuleId $natRule1.Id, $natRule2.Id -NetworkSecurityGroupId $nsg.id
	    }else{
            
            if($quantity -eq 2 -and $vmNum -eq 1){
                if($xcl8Net){
                    $nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId  -EnableAcceleratedNetworking -PrivateIpAddress $cgf1nic1InternalIP -EnableIPForwarding -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $BackendPool.Id
                
                }else{
                    $nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId  -PrivateIpAddress $cgf1nic1InternalIP -EnableIPForwarding -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $BackendPool.Id
                }
	        }elseif($quantity -eq 2 -and $vmNum -eq 2){
                if($xcl8Net){
                    $nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId -EnableAcceleratedNetworking -PrivateIpAddress $cgf2nic1InternalIP -EnableIPForwarding -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.id 
                
                }else{
                    $nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId  -PrivateIpAddress $cgf2nic1InternalIP -EnableIPForwarding -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.id 
                }
            }else{
                if($xcl8Net){
                    $nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId  -EnableAcceleratedNetworking -EnableIPForwarding -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $BackendPool.Id
                
                }else{
                    $nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName -SubnetId $SubnetId   -EnableIPForwarding -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $BackendPool.Id
                }
            }

            #Repeat tests for second NIC
            if($quantity -eq 2 -and $vmNum -eq 1 -and $nicName2){
                if($xcl8Net){
                    $nic2 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $Subnet2Id -EnableAcceleratedNetworking -PrivateIpAddress $cgf1nic2InternalIP -EnableIPForwarding  -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $intBackendPool.Id
                
                }else{
                    $nic2 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $Subnet2Id  -PrivateIpAddress $cgf1nic2InternalIP -EnableIPForwarding  -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $intBackendPool.Id
                }
	        }elseif($quantity -eq 2 -and $vmNum -eq 2 -and $nicName2){

                if($xcl8Net){
                    $nic2 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $Subnet2Id -EnableAcceleratedNetworking -PrivateIpAddress $cgf2nic2InternalIP -EnableIPForwarding  -NetworkSecurityGroupId $nsg.id
                
                }else{
                    $nic2 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $Subnet2Id  -PrivateIpAddress $cgf2nic2InternalIP -EnableIPForwarding  -NetworkSecurityGroupId $nsg.id 
                }
            }elseif($nicName2){
                            
                if($xcl8Net){
                    $nic2 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $Subnet2Id  -EnableAcceleratedNetworking  -EnableIPForwarding -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $intBackendPool.Id
                
                }else{
                    $nic2 = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location -Name $nicName2 -SubnetId $Subnet2Id   -EnableIPForwarding -NetworkSecurityGroupId $nsg.id -LoadBalancerBackendAddressPoolId $intBackendPool.Id
                }

            }

        }
    




    # Create the VM Configuration

    Write-Verbose 'Creating CGF VM Configuration'
    if($vmAvZone){
        $vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize -Zone $vmNum
    }else{
        $vm = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $vmAvSet.Id
    }

    
    if($quantity -eq 2 -and $vmNum -eq 1 -and $cgfcustomData1){
        $vm = Set-AzVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -CustomData $cgfCustomData1 -ErrorAction Stop
       
    }elseif($quantity -eq 2 -and $vmNum -eq 2 -and $cgfcustomData2){
        $vm = Set-AzVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -CustomData $cgfCustomData2 -ErrorAction Stop
    }else{

        $vm = Set-AzVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred -ErrorAction Stop
    }

    

    # Add primary network interface
    $vm = Add-AzVMNetworkInterface -VM $vm -Id $nic.Id -ErrorAction Stop -Primary

    # If the second NIC was created earlier this will be associated to the VM here.
    if($nic2){
	    $vm = Add-AzVMNetworkInterface -VM $vm -Id $nic2.Id -ErrorAction Stop 
    }

    #If there are no managed disks requested then generates the URI's

    if(!$useManagedDisks){
        # generate the name for the OS disk
        $osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $diskName
    }



    # Specify the OS disk with user image
    if ($customSourceImageUri -eq '')
    {
        Write-Verbose 'Using $($VmVersion) image from the Azure Marketplace'
        $vm.Plan = @{'name'= $vmLicenseType; 'publisher'= 'barracudanetworks'; 'product' = $vmProductType}
        $vm = Set-AzVMSourceImage -VM $vm -PublisherName 'barracudanetworks' -Skus $vmLicenseType -Offer $vmProductType -Version $vmVersion -ErrorAction Stop
        
    
        if($useManagedDisks){
            $vm = Set-AzVMOSDisk -VM $vm -Name $diskName -StorageAccountType $storageType -DiskSizeInGB 128 -CreateOption FromImage
        }else{
            # Set the name and storage for the OS Disk image.
            $vm = Set-AzVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
        }
    }
    else
    {
        Write-Verbose ('Using user defined image {0}' -f $customSourceImageUri)
        if(!$useManagedDisks){
            # Set the name and storage for the OS Disk image.
            $vm = Set-AzVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $customSourceImageUri -Linux 
        }else{
             $image.StorageProfile.OsDisk.StorageAccountType = $storageType
             $vm =  Set-AzVMSourceImage -VM $vm -Id $image.Id
        }
    }

#Adds the data disks
    if($useManagedDisks -and $vmProductType -ne "waf" -and $datadiskQty -ge 1){
        Write-Verbose "Adding $($diskNum) data disks"
        For($diskNum=1;$DiskNum -le $datadiskQty;$diskNum++){
       
            $datadiskName = Invoke-Command $datadiskNameDef
            $vm = Add-AzVMDataDisk -VM $vm -Name $datadiskName -DiskSizeInGB $datadisksize -CreateOption Empty -Lun $diskNum
        }
    }elseif($vmProductType -ne "waf" -and $datadiskName1){
        Write-Verbose "Adding $($diskNum) data disks"
        For($diskNum=0;$DiskNum -le $datadiskQty;$diskNum++){
       
            $datadiskName = Invoke-Command $datadiskNameDef
            $dataDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $datadiskName
            $vm = Add-AzVMDataDisk -VM $vm -Name $datadiskName1 -DiskSizeInGB $datadisksize -CreateOption Empty -Lun $diskNum -VhdUri $dataDiskUri
        }
        
      
    }


    Write-Verbose 'Creating Barracuda Cloud Gen Firewall VM. This can take a while ....'
    #pause
    $result = New-AzVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vm 

    #Updates LB pools after provisioning of VM
    if($lbSku -eq "Standard" -and !$nicName2){
         $nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -LoadBalancerBackendAddressPoolId $BackendPool.Id,$intBackendPool.Id -PublicIpAddressId $pip.Id | Set-AzNetworkInterface -OutVariable $setnic | Out-Null
    }else{
        $nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -LoadBalancerBackendAddressPoolId $BackendPool.Id -PublicIpAddressId $pip.Id | Set-AzNetworkInterface -OutVariable $setnic | Out-Null
        $nic2 | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -LoadBalancerBackendAddressPoolId $intBackendPool.Id | Set-AzNetworkInterface -OutVariable $setnic | Out-Null
    }

    if($result.IsSuccessStatusCode -eq 'True') {
       $result
        if($vmProductType -eq 'waf'){
            Write-Host ('Barracuda CGF WAF VM ''{0}'' was successfully deployed.  Connect to the firewall at http://{2}:8001 with the username: admin and password: {1}' -f $vmName, $rootPassword, (Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $ipName).IpAddress)
        }else{
            Write-Host ('Barracuda CGF Firewall VM ''{0}'' was successfully deployed.  Connect to the firewall at {2} with the username: root or and password: {1}' -f $vmName, $rootPassword, (Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $ipName).IpAddress)

        }
    } else {
        Write-Host ('Deployment Failed. {0}' -f $result.ReasonPhrase)
    }

    


} #End For loop that can create clusters.
