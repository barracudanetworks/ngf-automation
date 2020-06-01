
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

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string]$listname,

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
$included_source,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$included_destination,


[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$excluded_source,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$excluded_destination,

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
$service_reference,

#policies

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$policies=@{"ips"="Default"},


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

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[ValidateSet("block", "deny", "pass", "dnat", "appredirect", "map", "group", "cascade", "cascadeback")] 
[string]$action_type,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
$action_rulelist,

#common rule values
[Parameter(Mandatory=$true,
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
[bool]$dynamic=$false,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[ValidateSet("IPv4", "IPv6")] 
[string]$ipversion="IPv4",

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$rcsMessage

)


    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    
    If ($PSBoundParameters['Debug']) {
        $DebugPreference = 'Continue'
    }
    Write-Debug "Provide PSBoundParameters" 

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
        Write-Debug "$($key) : $($value)"
    }

    #create hashtable to become json, add in simple objects here.

    $postParams = @{}
    $postParams.Add("name",$name)
    $postParams.Add("comment",$comment)
    $postParams.Add("bidirectional",$bidirectional)
    $postParams.Add("deactivated",$deactivated)
    $postParams.Add("dynamic",$dynamic)
    $postParams.Add("ipVersion",$ipversion)
    if($rcsMessage){$postParams.Add("rcsMessage",$rcsMessage)}

   #Following section adds in the more complex decisions.


   #SECTION HANDLING POSITIONING
    $postParams.Add("position",@{"placement"=$PSBoundParameters.placement})

    if($placement -eq "exact"){
        $postParams.position += @{"index"=$PSBoundParameters.index}
      #  [Void]$PSBoundParameters.Remove("placement")
      #  [Void]$PSBoundParameters.Remove("index")
    }
    if(($placement -eq "before") -or ($placement -eq "after")){
        $postParams.position += (@{"reference"=$PSBoundParameters.reference})
       # [Void]$PSBoundParameters.Remove("placement")
       # [Void]$PSBoundParameters.Remove("reference")
    }
    #Removes placement 
   # [Void]$PSBoundParameters.Remove("placement")


   #SECTION HANDLING THE SOURCE AND DESTINATION OBJECTS

    $postParams.Add("source", @{})
    $postParams.Add("destination", @{})
    $postParams.Add("service", @{})

    #Organises the source and destination objects
    if($included_source){
        $postParams.source += @{"explicit"=@{"included"=@($included_source)}}
    }
    if($included_destination){
        $postParams.destination += @{"explicit"=@{"included"=@($included_destination)}}
    }

        #Organises the source and destination objects
    if($excluded_source){
        $postParams.source += @{"explicit"=@{"excluded"=@($excluded_source)}}
    }
    if($excluded_destination){
        $postParams.destination += @{"explicit"=@{"excluded"=@($excluded_destination)}}
    }

    if($source_reference){
        #Can be provided array or single reference object
        if($source_reference.GetType().BaseType.Name -eq "Array"){
            foreach($src in $source_reference){
                $postParams.source += @{"references"=$src}    
            }
        }else{
            $postParams.source += @{"references"=$source_reference}
        }
    #    [Void]$PSBoundParameters.Remove("source_reference")
    }
    if($destination_reference){
        #Can be provided array or single reference object
        if($destination_reference.GetType().BaseType.Name -eq "Array"){
            foreach($dst in $destination_reference){
                $postParams.destination += @{"references"=$dst}    
            }
        }else{
            $postParamsdestination += @{"references"=$destination_reference}
        }
       # [Void]$PSBoundParameters.Remove("destination_reference")
    }
    
   
    
    #SECTION HANDLING SERVICE OBJECTS - use the Convert-BarracudaCGFServiceObject to build the array for this
    if($service_explicit){
            $postParams.service += @{"explicit" = @{"entries" = $service_explicit}}
      #  [Void]$PSBoundParameters.Remove("service_explicit")
    }

    if($service_reference){
        if($service_reference.GetType().BaseType.Name -eq "Array"){
            $postParams.service.Add("explicit",@{"entries"=@()})
            foreach($svc in $service_reference){
               $postParams.service.explicit.entries += @{"references"="$($svc)"}

            }
        }else{
            $postParams.service= @{"references"=$service_reference}
        }
        #[Void]$PSBoundParameters.Remove("service_references")
    }


    #SECTION HANDLING ACTION OBJECTS

    $postParams.Add("action", @{"type" = $action_type})
  #  [Void]$PSBoundParameters.Remove("action_type")
    
    if($action_reference){
        $postParams.action += @{"connection" = @{"references"=$action_reference}}
     #   [Void]$PSBoundParameters.Remove("action_reference")
    }

    if($action_target -and ($action_type -eq "appredirect")){
        $postParams.action = @{"target" = @{"address"="$($action_target.split(":")[0])";"port"="$($action_target.Split(":")[1])"}}
    #    [Void]$PSBoundParameters.Remove("action_target")
    }elseif(!$action_target -and ($action_type -eq "appredirect")){
        Write-Error -Message "Missing target for App Redirect rule type"
        throw
    }

    if($action_targets -and ($action_type -eq "dnat")){
        $postParams.action.targets = $action_targets
       # [Void]$PSBoundParameters.Remove("action_targets")
    }elseif(!$action_targets -and ($action_type -eq "dnat")){
        Write-Error -Message "Missing targets for Destination NAT rule type"
        throw
    }

    if($action_destination -and ($action_type -eq "map")){
        $postParams.action.destination = $action_destination
      #  [Void]$PSBoundParameters.Remove("action_destination")
    }elseif(!$action_destination -and ($action_type -eq "map")){
        Write-Error -Message "Missing destination for MAP rule type"
        throw
    }
    
    if($action_rulelist -and ($action_type -eq "cascade")){
        $postParams.action.rulelist = $action_rulelist
      #  [Void]$PSBoundParameters.Remove("action_rulelist")
    }elseif(!$action_rulelist -and ($action_type -eq "cascade")){
        Write-Error -Message "Missing targets for cascade rule type"
        throw
    }

    #SECTION HANDLING POLICIES
    if($policies){
        $postParams.Add("policies",$policies)
    }
    

    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    #Inserts the tail of the API path to the parameters 
    $PSBoundParameters["context"] = "rules"

    #builds the REST API path.
    $url = Set-RESTPath @PSBoundParameters
    
    $data = ConvertTo-Json $postParams -Depth 99
    
        Write-Debug $url
        Write-Debug $data

        
        try{
               $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing
        }catch [System.Net.WebException] {
                $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                Write-Error $results
                return $results  
            }



return $results
}