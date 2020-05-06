
<#
.Synopsis
	Creates a new firewall rule
.Description
    This function will create a new network object in either the Host Firewall or Forwarding Firewall. It expects input of either the -included, excluded, includedReferences or -excludedReferences parameters to create the object
    -geo should be an hashtable of arrays @{"included"=@('Austria','Europe');"excluded"=@("US","Russia")}
.Example
	New-BarracudaNGFNetworkObject -deviceName <hostname or ip> -devicePort 8443 -creds <powershell credentials> -Type generic -name <objectname> -included @(@{"entry"=@{ip="$($i)"}},@{"entry"=@{ip="$($i)"}},@{"entry"=@{ip="$($i)"}}) 
.Notes
v0.1
#>

Function New-BarracudaCGFFirewallRule {
[cmdletbinding()]
param(
#These are the general access parameters
[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$false)]
[string] $token,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string] $devicePort=8443,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$notHTTPs,

#the below define where the rule is created host or forwarding, cc or local.

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
ValueFromPipelineByPropertyName=$false)]
[switch]$hostfirewall,

#The following parameters are for the position of the rule in ruleset

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[ValidateSet("exact", "top", "bottom", "before", "after")] 
[string]$placement,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[int]$index,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$reference,

#The following parameters are for the rule contents
#starting with the source and destination network objects

#Use the New-BarracudaCGFServiceObject to build this - so provide PS Object

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$source,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$destination,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$source_reference,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$destination_reference,

<#
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$source_explicit_included,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$source_references_included,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$source_explicit_excluded,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$source_references_excluded,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$destination_explicit_included,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$detination_references_included,


[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$destination_explicit_excluded,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$destination_references_excluded,

#>
#service objects
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$service_explicit,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$service_references,

#policies

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$policies,


#action - powershll object built from New-BarracudaCGFConnectionObject
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$action_reference,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$action_target,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$action_targets,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$action_destination,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[hashtable]$action_map,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[ValidateSet("block", "deny", "pass", "dnat", "appredirect", "map", "group", "cascade", "cascadeback")] 
$action_type,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$action_rulelist,

#common rule values
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$name,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$comment,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[bool]$bidirectional = $false,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[bool]$deactivated = $false,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[bool]$dynamic = $false,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[ValidateSet("IPv4", "IPv6")] 
[string]$ipversion="IPv4",


[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$rcsMessage

)

    #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }

    #Sets the token header
    $header = @{"X-API-Token" = "$token"}


#defines the URL to call
    if($cc){
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/cc/v1/config"
        
        if($range -and $cluster -and $serverName -and $serviceName){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/servers/$($PSBoundParameters.("serverName"))/services/$($PSBoundParameters.("serviceName"))"
        }elseif($range -and $cluster -and $box){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/boxes/$($PSBoundParameters.("box"))"
        }elseif($range -and $cluster -and $serviceName){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/services/$($PSBoundParameters.("serviceName"))"
        }elseif($range -and $cluster){
              $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))"
        }elseif($range){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))"
        }
        else{
        #assume global
            $url = $url + "/global"
        }
        if($sharedfw){
             $url = $url + "/shared-firewall/rules"
        }else{
            $url = $url + "/firewall/rules"
        }
    }else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/config/v1"
        if($hostfirewall){
            $url = $url + "/box/firewall/rules"
        }else{
            if($serviceName -and $virtualServer){
               $url = $url + "/servers/$($virtualServer)/services/$($serviceName)/firewall/rules"
            }else{
            $url = $url + "/forwarding-firewall/rules"

            }
        }
    }

    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Verbose $PSBoundParameters
    }

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
    }
    
    #Void's anything we don't want
    [Void]$PSBoundParameters.Remove("token")
    [Void]$PSBoundParameters.Remove("devicePort")
    [Void]$PSBoundParameters.Remove("deviceName")
    if($PSBoundParameters.ContainsKey("Debug")){$Debug=$true;  $VerbosePreference="continue"; [Void]$PSBoundParameters.Remove("Debug")}
    
    #Creates the position objects
    $PSBoundParameters.position = @{"placement"=$PSBoundParameters.placement}

    if($PSBoundParameters.placement -eq "exact"){
        $PSBoundParameters.position += @{"index"=$PSBoundParameters.index}
        [Void]$PSBoundParameters.Remove("placement")
        [Void]$PSBoundParameters.Remove("index")
    }
    if(($PSBoundParameters.placement -eq "before") -or ($PSBoundParameters.placement -eq "after")){
        $PSBoundParameters.position += (@{"reference"=$PSBoundParameters.reference})
        [Void]$PSBoundParameters.Remove("placement")
        [Void]$PSBoundParameters.Remove("reference")
    }

    $PSBoundParameters.source= @{}
    $PSBoundParameters.destination= @{}

    #Organises the source and destination objects
    if($PSBoundParameters.source){
        $PSBoundParameters.source += @{"explicit"=$PSBoundParameters.source}
    }
    if($PSBoundParameters.destination){
        $PSBoundParameters.destination += @{"explicit"=$PSBoundParameters.destination}
    }

    if($PSBoundParameters.source_reference){
        $PSBoundParameters.source += @{"references"=$PSBoundParameters.source_reference}
        [Void]$PSBoundParameters.Remove("source_reference")
    }
    if($PSBoundParameters.destination_reference){
        $PSBoundParameters.destination += @{"references"=$PSBoundParameters.destination_reference}
        [Void]$PSBoundParameters.Remove("destination_reference")
    }
    
    #service_object handling - use the New-BarracudaCGFServiceObject to build the array for this
    if($PSBoundParameters.service_explicit){
        $PSBoundParameters.service = @{"explicit" = $PSBoundParameters.service_explicit}
        [Void]$PSBoundParameters.Remove("service_explicit")
    }

    if($PSBoundParameters.service_references){
        $PSBoundParameters.service= @{"references"=$PSBoundParameters.service_references}
        [Void]$PSBoundParameters.Remove("service_references")
    }

    #action handling
    $PSBoundParameters.action = @{"type" = $action_type}
    [Void]$PSBoundParameters.Remove("action_type")
    
    if($action_reference){
        $PSBoundParameters.action = @{"connection" = @{"references"=$action_reference}}
        [Void]$PSBoundParameters.Remove("action_reference")
    }

    if($action_target -and ($action_type -eq "appredirect")){
        $PSBoundParameters.action = @{"target" = @{"address"="$($action_target.split(":")[0])";"port"="$($action_target.Split(":")[1])"}}
        [Void]$PSBoundParameters.Remove("action_target")
    }elseif(!$action_target -and ($action_type -eq "appredirect")){
        Write-Error -Message "Missing target for App Redirect rule type"
        throw
    }

    if($action_targets -and ($action_type -eq "dnat")){
        $PSBoundParameters.action.targets = $action_targets
        [Void]$PSBoundParameters.Remove("action_targets")
    }elseif(!$action_targets -and ($action_type -eq "dnat")){
        Write-Error -Message "Missing targets for Destination NAT rule type"
        throw
    }

    if($action_destination -and ($action_type -eq "map")){
        $PSBoundParameters.action.destination = $action_destination
        [Void]$PSBoundParameters.Remove("action_destination")
    }elseif(!$action_destination -and ($action_type -eq "map")){
        Write-Error -Message "Missing destination for MAP rule type"
        throw
    }
    
    if($action_rulelist -and ($action_type -eq "cascade")){
        $PSBoundParameters.action.rulelist = $action_rulelist
        [Void]$PSBoundParameters.Remove("action_rulelist")
    }elseif(!$action_rulelist -and ($action_type -eq "cascade")){
        Write-Error -Message "Missing targets for cascade rule type"
        throw
    }

    $data = ConvertTo-Json $PSBoundParameters -Depth 99
    
      
    if($Debug){
        Write-Verbose $PSBoundParameters
        Write-Verbose $url
        Write-Verbose $data

        try{
            Write-Host $data
            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing -Debug
        }catch [System.Net.WebException] {
                $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                Write-Error $results
                throw   
            }
    }else{
        
        try{
            Write-Host $data
            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing
        }catch [System.Net.WebException] {
                $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                Write-Error $results
                throw   
            }

    }

return $results
}