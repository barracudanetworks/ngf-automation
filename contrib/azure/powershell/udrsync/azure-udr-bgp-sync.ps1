<#
    .SYNOPSIS
        This Azure Automation runbook automates syncing of the BGP/ExpressRoutes routing entries into the UDR route table. 

    .DESCRIPTION
        The runbook implements a solution for scheduled power management of Azure virtual machines in combination with tags
        on virtual machines or resource groups which define a shutdown schedule. Each time it runs, the runbook looks for all
        virtual machines or resource groups with a tag named "AutoShutdownSchedule" having a value defining the schedule, 
        e.g. "10PM -> 6AM". It then checks the current time against each schedule entry, ensuring that VMs with tags or in tagged groups 
        are shut down or started to conform to the defined schedule.

        This is a PowerShell runbook. It requires the AzureRM.Network and AzureRM.profile modues to be installed.

        This runbook requires the "Azure" module which are present by default in Azure Automation accounts. This runbook also requires 
        the "AzureRM.profile" and "AzureRM.Network" modules which need to be added into the Azure Automation account.

    .PARAMETER NGF_VM_IFC_Name
        The name of the interface that has the routing information towards BGP/ExpressRoute

    .PARAMETER NGF_VM_IFC_RG
        The Resource Group containing the network interface references in NGF_VM_IFC_Name

    .PARAMETER NGF_VM_IP
        The private IP address of the Barracuda NextGen Firewall. This will be used to route the traffic to 

    .PARAMETER RT_Name
        The name of the route table that needs to be updated. Traffic from the atteched subnets needs to be send to the Barracuda NextGen Firewall 

    .PARAMETER RT_RG
        The Resource Group containing the route table

    .PARAMETER Simulate
        If $true, the runbook will not perform any actions and will only read the routing table but not set the routes. (Simulate = $false).

    .PARAMETER Private_IP
        If $true, the runbook will not catch  (Private_IP = $false).

    .NOTES
        AUTHOR: Joeri Van Hoof (jvanhoof@barracuda.com)
        LASTEDIT: 10 October 2017
#>

param(
    [parameter(Mandatory=$true)]
    [String] $NGF_VM_IFC_Name = "Network interface name of the NGF",
    [parameter(Mandatory=$true)]
    [String] $NGF_VM_IFC_RG = "Resource group containing the NGF",
    [parameter(Mandatory=$true)]
    [String] $NGF_VM_IP = "Private IP address of the NGF",
    [parameter(Mandatory=$true)]
    [String] $RT_Name = "Route table for the services protected by the NGF",
    [parameter(Mandatory=$true)]
    [String] $RT_RG = "Resource group containing the route table",
    [parameter(Mandatory=$false)]
    [bool] $Simulate = $false,
    [parameter(Mandatory=$false)]
    [bool] $private_ip = $false
)

$VERSION = "1.0"

$src = @{}
$dst = @{}

# Variable to track if we need to save any changes
$Update = 0
$count = 0

function ConvertTo-BinaryIP( [String]$IP ) { 
 
  $IPAddress = [Net.IPAddress]::Parse($IP) 
 
  Return [String]::Join('.', 
    $( $IPAddress.GetAddressBytes() | %{ 
      [Convert]::ToString($_, 2).PadLeft(8, '0') } )) 
} 
 
 
function IsPrivateNetwork( [String]$IP ) { 
    If ($IP.Contains("/")) { 
        $Temp = $IP.Split("/") 
        $IP = $Temp[0] 
    } 
   
    $BinaryIP = ConvertTo-BinaryIP $IP; $Private = $False 
   
    Switch -RegEx ($BinaryIP) { 
        "^1111" { $Class = "E"; $SubnetBitMap = "1111" } 
        "^1110" { $Class = "D"; $SubnetBitMap = "1110" } 
        "^110"  { $Class = "C" 
                    If ($BinaryIP -Match "^11000000.10101000") { $Private = $True }  
                } 
        "^10"   { $Class = "B" 
                    If ($BinaryIP -Match "^10101100.0001") { $Private = $True } } 
        "^0"    { $Class = "A" 
                    If ($BinaryIP -Match "^00001010") { $Private = $True }  
                } 
    }    
    return $Private 
}

function Get-RouteName($addressPrefix) {
    $ip = $addressPrefix.Split('/');
    $ip2 = ($ip[0].Split('.') | foreach {"{0:000}" -f [int]$_}) -join ''
    return "R" + $ip2 + "M" + $ip[1]
}

$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
} catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try {
    # Reading the NGF subnet routetable. This routetable contains the BGP/ExpressRoutes that need to be duplicated
    $RT1 = Get-AzureRmEffectiveRouteTable -NetworkInterfaceName $NGF_VM_IFC_Name -ResourceGroupName $NGF_VM_IFC_RG
    foreach ($element in $RT1) {
        $t = IsPrivateNetwork($element.AddressPrefix.Item(0))
        if( $Private_IP -And (-Not $t ) ) {
            Continue
        }
        if( ($element.NextHopType.CompareTo("VirtualNetworkGateway") -eq 0) -And (-Not $src.ContainsKey($element.AddressPrefix.Item(0)) ) ) {
            $src.add($element.AddressPrefix.Item(0), $element.Name)
        }
    }

    # Reading the route table that needs updating
    $RT2 = Get-AzureRmRouteTable -Name $RT_Name -ResourceGroupName $RT_RG
    foreach ($element in $RT2.Routes) {
        if( ($element.NextHopType.CompareTo("VirtualAppliance") -eq 0) -And (-Not $src.ContainsKey($element.AddressPrefix)) ) {
            $dst.Add($element.AddressPrefix, $element.Name)
        }
    }

    # Add missing routes to the route Table.
    foreach($element in $src.Keys) {
        if($dst.Keys -notcontains $element) {
            $routename = $src.Get_Item($element)
            if( !$routename ) {
                $routename = Get-RouteName($element)
            }
            Write-Host "Adding route $element with name $routename to routetable $RT_Name"
            $Update = 1
            $count++
            if(!$Simulate) {
                Add-AzureRmRouteConfig -Name $routename -AddressPrefix $element -NextHopType VirtualAppliance -NextHopIpAddress $NGF_VM_IP -RouteTable $RT2
            }
        }
    }

    # Remove routes that are no longer in the BGP/ExpressRoute list
    # Caveat: Any route in the route table that doesn't have the naming convention given by this script will not be deleted.
    foreach($element in $dst.Keys) {
        if($src.Keys -notcontains $element) {
            $routename = $dst.Get_Item($element)
            $routename = Get-RouteName($element)
            if( $routename -eq $dst.Get_Item($element) ) {
                Write-Host "Removing route $element with name $routename to routetable $RT_Name"
                $Update = 1
                if(!$Simulate) {
                    Remove-AzureRmRouteConfig -Name $routename -RouteTable $RT2
                }
            }
        }
    }


    # only if there are updates to the routes an update is pushed to the routetable
    if( $Update ) {
        Write-Host "Saving routetable $RT_Name"
        if(!$Simulate) {
            Set-AzureRmRouteTable -RouteTable $RT2
        } else {
            echo $RT2
        }
    }

} catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

