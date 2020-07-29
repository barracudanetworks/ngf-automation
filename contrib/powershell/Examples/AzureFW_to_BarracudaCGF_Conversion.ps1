<#
.SYNOPSIS
    This script queries the Azure firewall and creates Barracuda Firewall rules based upon the ruleset of the Azure FW
    The script can be ran in a offline mode whereby the Azure FW rules are provided in a CSV format.
.DESCRIPTION
    The script works through the Azure Firewall rule list and transfers them into a Barracuda Firewall ruleset. The script when ran in online mode will directly query Azure for the Azure FW ruleset and the IPGroups. 
    You must log into Azure first to operate in online mode.
    In offline mode you can provide a CSV input files to act as both the ipgroups and the rulese and the script will insert these.
    If you are using self-signed certificates then before starting the script please run: Set-BarracudaCGFtoIgnoreSelfSignedCerts -allowSelfSigned -noCRL 

.PARAMETERS
    -deviceName 
        Specifies the name/fqdn of the firewall or Control center
    -devicePort
        Specified the port of the API if not the standard 8443
    -token
        Provides authentication token to API
    -virtualServer
        Particularly important when running via a Control Center, provides the name of the Virtual server. Will default to the v8 convention if left blank
    -serviceName 
        Specifies the name of the virtual service, will default to NGFW
    -box
        Specifies the name of the firewall box, required when running against Control Center
    -listname
        Specifies a seperate rule list to add objects to. 
    -firewallnName 
        Specifies the name of the Azure FW to collect information from
    -fwresourcegroup
        Specifies the name of the Azure FWs resource group
    -offlinesourcefile
        Uses a CSV file input instead of querying the AzureFW online.
    -offlineipgroupfile
        Uses a CSV file containing the existing IP groups, for offline use otherwise the script will query Azure directly
    -offlineaction
        When provided a CSV dump no action is included. Specifies the action to create rules with
    -removeduplicates 
        Perform depulication of source and destination IP addresses.
        

.Example
    Online mode example
    ./AzureFW_to_BarracudaCGF_Conversion.ps1 -deviceName $barracudacc -token $barracudacctoken -range $range -cluster $cluster -serviceName $servicename -box $box -listName $rulelistname -azureFWname $firewallname -azureFWResourceGroup $fwresourcegroup

    Offline mode example
    ./AzureFW_to_BarracudaCGF_Conversion.ps1 -deviceName $barracudacc -token $barracudacctoken -range $range -cluster $cluster -serviceName $servicename -box $box -listName $rulelistname -offlinesourcefile $offlinesourcefile -offlineipgroupfile $offlineipgroupfile -offlineaction Allow -removeduplicates $true 

.Notes
First version, only creates FW rules at this time. Offline input expects a single series of rules in the CSV file.
v0.1
#>


[cmdletbinding()]
param(
[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$false)]
[string] $token,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string] $devicePort=8443,

#the below parameters define the ruleset to create the object in
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$virtualServer,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$serviceName,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$range,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$cluster,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$box,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$listName,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$notHTTPs,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string]$azureFWname,


[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string]$azureFWResourceGroup,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string]$offlinesourcefile,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string]$offlineipgroupfile,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string]$offlineaction="Allow",

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[bool]$removeduplicates=$false


)

#Imports the Barracuda Module
Import-Module BarracudaCGF -Force

if($offlinesourcefile){
    Write-Verbose "Offline file selected, importing CSV"
    #quickest way of making an object that I found right now.
    $csvimport = ConvertFrom-Json(ConvertTo-Json(Import-Csv -Path $offlinesourcefile -Delimiter ","))
    $netrules = @{"Name"="CSGImport";"Action"=@{"Type"="$($offlineaction)"}; "Priority"=100;"Rules"=$csvimport}

}else{
    Write-Verbose "Performing information gathering, collecting info on Azure Firewall"
    $azfw = Get-AzFirewall -Name "$($azureFWname)" -ResourceGroupName $azureFWResourceGroup
        #defines the 3 types of rules to translate
    $netrules = $fw.NetworkRuleCollections
    $nats = $fw.NatRuleCollections
    $apprules = $fw.ApplicationRuleCollections
}

Write-Verbose "Collecting ruleset of Barracuda FW"
$barfw = Get-BarracudaCGFFirewallRule -deviceName $deviceName -token $token -range $range -cluster $cluster -box $box -serviceName $servicename -listname "$($listname)" -details
Write-Verbose "Collecting Service Objects for Barracuda FW"
$serviceobjects = Get-BarracudaCGFServiceObject -deviceName $deviceName -token $token -range $range -cluster $cluster -box $box -serviceName $servicename -details
Write-Verbose "Collecting Network Objects for Barracuda FW"
$networkobjects = Get-BarracudaCGFNetworkObject -deviceName $deviceName -token $token -range $range -cluster $cluster -box $box -serviceName $servicename -details




if($offlineipgroupfile){
    $ipgroupimport = ConvertFrom-Json(ConvertTo-Json(Import-Csv -Path $offlineipgroupfile -Delimiter ","))
    
}


#Converts FW rules to FW rules
        #1. Created Service Object for protocol
        #2. Creates Source network object
        #3. Created destination network object
        #4. Takes default connection object of Original Source IP
        #5. Convert Action Type          
$i=0           
foreach($entry in $netrules | Sort-Object -Property Priority){
    Write-Verbose "$($entry.Action.Type)"
    
    #Converts Azure FW rule types to Barracuda
    switch($entry.Action.Type){
       "Allow" { $action = "pass" }
       "Deny" {  $action = "block" }
       default { $action = "deny" }
    }

    foreach($rule in $entry.Rules){
        $i++
        Write-Output "$($i). CREATING FROM AZURE FW: $($rule.Name) DST: $($rule.DestinationAddresses) SRC: $($rule.SourceAddresses) PROTO: $($rule.Protocols) DSTPORT: $($rule.DestinationPorts)"
        
        $objectout= @()
        $serviceref = @()

        #replacing uacceptable characters from names
        $rulename = "$($entry.Name)-$($entry.Priority)-$(($rule.Name))".Replace("_","-") -replace '[~#%&*{}\\:<>?/|+_",\s]'
        if($rule.Description.Length -gt 2){$rule.Description = ($rule.Description).Replace("_","-") -replace '[~#%&*{}\\:<>?/|+_",\s]'}
        

        $scriptblock = "New-BarracudaCGFFirewallRule -deviceName $deviceName -devicePort $devicePort -token $token -range $range -cluster $cluster -box $box -serviceName $servicename -placement bottom ``
        -action_reference `"Original Source IP`" -action_type $($action) -name `"$($rulename)`" -comment `"Imported from Azure Firewall - $($rule.Description) - $(Get-Date -Format "yyyy-MM-dd")`" ``"

        if($listName){
            $scriptblock += " -listname $listName "
        }

        #This is the logic to test for existing service objects and use them where possible. 
        Write-Verbose "Testing for existing service object"
        
        
        #Converts CSV to Array
        if($offlinesourcefile){$rule.Protocols = $rule.Protocols.Split(",");$rule.DestinationPorts = $rule.DestinationPorts.Split(",")}

        foreach($proto in $rule.Protocols){
            Write-Verbose "Checking for protocol $($proto)"

            if($($rule.Protocols) -eq "Any"){
                    Write-Verbose "This rule allows any service, setting service reference to Any"
                    $serviceref = @("Any")
            }else{
                #This is restrictive only looking for matches where a single port is present (e.g won't match entire AD group if you only have port 389.
                $useobject = ($serviceobjects | Where-Object -FilterScript {$_.Entries.Entry.Protocol -eq "$($proto.ToLower())" -and $_.entries.entry."$($proto.ToLower())".ports -eq $($rule.DestinationPorts) -and $_.entries.count -eq 1}).Name
                if(!$useobject){
                
                        Write-Verbose "No existing Service Object found"
                        $objectout += Convert-BarracudaCGFServiceObject -protocol "$($proto.ToLower())" -ports $rule.DestinationPorts -Comment "Created for Azure FW $($rulename) Conversion"
                        Write-Output "CREATING SERVICE OBJECT: $($objectout.entry.ports)"
                                        
                }else{
                    #This will become a reference in the rule....
                    Write-Verbose "Found Service Object :$($useobject) creating reference" 
                    $serviceref += "$($useobject)"
            
                }
            }

            [void]$useobject
            

        }#end proto foreach

        #adds the services to the scriptblock
        if($objectout){
            $scriptblock += " -service_explicit `$objectout"
        }else{
            $scriptblock += " -service_reference $serviceref"
        }

        #Handle IP Groups
        if($rule.SourceIpGroups){

           Write-Verbose "Azure FW using IP Group, gathering info" 
           if(!$offlineipgroupfile){
                $srcipgroup =  Get-AzIpGroup -ResourceId "$($rule.SourceIpGroups)"
           }
           #Check for existing one.

           $existingnetobj = ($networkobjects | Where-Object -FilterScript {$_.name -eq $srcipgroup.Name})
           
           if(!$existingnetobj){
                #Make Network Object from IP Group
                Write-Output "Creating new network object for IP group $($srcipgroup.Name))"
                
                if($offlineipgroupfile){ $srcipgroup.IpAddresses = (($ipgroupimport | Where-Object -Property "IP group" -EQ -Value "$($rule.SourceIpGroups)")."IP address, range or subnet").Split(","); $srcipgroup.Name = ($ipgroupimport | Where-Object -Property "IP group" -EQ -Value "$($rule.SourceIpGroups)")."IP Group" }
                
                New-BarracudaCGFNetworkObject -deviceName $deviceName -token $token -range 1 -cluster $cluster -box $box -serviceName $servicename `
                -name ($srcipgroup.Name).Replace("_","-") -comment "created from ipgroup $($srcipgroup.Name), $($srcipgroup.ResourceGroupName) on  $(Get-Date)" `
                -type listIPv4Network -includedObjects (Convert-BarracudaCGFNetworkObject -objectType ipV4 -objectList $srcipgroup.IpAddresses -comment "member of Azure FW $($srcipgroup.Name) - $(Get-Date -Format "yyyy-MM-dd")")
                
                #Creates a source reference for the newly created object.
                $sourceref = @($srcipgroup.Name)

                #reload network objects
                $networkobjects = Get-BarracudaCGFNetworkObject -deviceName $deviceName -token $token -range 1 -cluster $cluster -box $box -serviceName $servicename -details

           }else{
                #Creates a source reference if the object already exists
                $sourceref = @($srcipgroup.Name)

           }

            #Otherwise create explicit objects
        }else{
            Write-Verbose "Creating an explicit source network object"
            if($rule.SourceAddresses -eq "*"){
                $sourceref = @("Any")
            }else{ 
                #Converts CSV to Array
                if($offlinesourcefile){$rule.SourceAddresses = $rule.SourceAddresses.Split(",")}
                if($removeduplicates){$rule.SourceAddresses = $rule.SourceAddresses | Select -Unique }
                $srcnetobj = Convert-BarracudaCGFNetworkObject -objectType ipV4 -objectList $rule.SourceAddresses  -comment "member of Azure FW $($rulename) - $(Get-Date -Format "yyyy-MM-dd")" 
            }
        }

        [void]$existingnetobj
        #adds the source to the scriptblock
        if($srcnetobj){
            $scriptblock += " -included_source `$srcnetobj"
        }else{
            $scriptblock += " -source_reference $sourceref"
        }



        if($rule.DestinationIpGroups){
           $dstipgroup =  Get-AzIpGroup -ResourceId "$($rule.DestinationIpGroups)"

           #Check for existing one.
           $existingnetobj = ($networkobjects | Where-Object -FilterScript {$_.name -eq $dstipgroup.Name})
           
           if(!$existingnetobj){
               #Make Network Object from IP Group
               if($offlineipgroupfile){ $dstipgroup.IpAddresses = ($ipgroupimport | Where-Object -Property "IP group" -EQ -Value "$($rule.DestinationIpGroups)")."IP address, range or subnet"  }

                New-BarracudaCGFNetworkObject -deviceName $deviceName -token $token -range $range -cluster $cluster -box $box -serviceName $servicename `
                -name $dstipgroup.Name -comment "created from ipgroup $($dstipgroup.Name), $($dstipgroup.ResourceGroupName)" `
                -type listIPv4Network -includedObjects (Convert-BarracudaCGFNetworkObject -objectType ipV4 -objectList $dstipgroup.IpAddresses -comment "member of Azure FW $($dstipgroup.Name) - $(Get-Date -Format "yyyy-MM-dd")")`

                $destinationref = @($dstipgroup.Name)

            }else{
                $destinationref = @($dstipgroup.Name)

            }
            #Otherwise create explicit objects
        }else{
            Write-Verbose "Creating an explict destination network object"
            
            #Replaces "*" with reference to "Any"
            if($rule.DestinationAddresses -eq "*"){
                $destinationref = @("Any")
            }else{
                #Converts CSV to Array
                if($offlinesourcefile){$rule.DestinationAddresses = $rule.DestinationAddresses.Split(",")} 
                if($removeduplicates){$rule.DestinationAddresses = $rule.DestinationAddresses | Select -Unique }           
                $dstnetobj = Convert-BarracudaCGFNetworkObject -objectType ipV4 -objectList $rule.DestinationAddresses -comment "member of Azure FW $($rulename) - $(Get-Date -Format "yyyy-MM-dd")"
            }
        }

        #adds the source to the scriptblock
        if($dstnetobj){
            $scriptblock += " -included_destination `$dstnetobj"
        }else{
            $scriptblock += " -destination_reference $destinationref"
        }
        
        
        #$scriptblock += " -Debug"     
        Write-Verbose "Creating Firewall rule using Original Source IP"
        #Create the Firewall rule.
        #pause
        
        #Check there isn't an existing rule with that name in this ruleset.
        if($barfw | Where-Object -FilterScript {$_.rules.Name -eq "$($rulename)"}){
            Write-Output "Error: Rule already exists with name: $($rulename)" 
        }else{
            Write-Host $scriptblock
            $results = ([Scriptblock]::Create($scriptblock).Invoke())

            if($results.StatusCode -eq 204){
                Write-Output "Success creating rule" 
            }else{
                Write-Output "Error with $($rulename) item $($i): $((ConvertFrom-Json $($results)).Message)" 
                pause
            }
        }
    
    }

    Write-Verbose "Completed rule creation"
    #for testing to see how we handle multi port objects
    

    #Clear down the values used.
    [void]$objectout
    [void]$serviceref
    [void]$destinationref
    [void]$sourceref
    [void]$scriptblock


}


#Need to Add NAT rules

#Need to add App rules.


Write-Output "Azure Firewall to Barracuda Firewall conversion complete"