<#
.Synopsis
	Creates a new network object in the firewall or returns a suitable powershell object for use with New-BarracudaCGFFirewallRule to create an explicit object
.Description
    This function will create a new network object in either the Host Firewall or Forwarding Firewall or return a powershell object. It expects input of either the -included, excluded, includedReferences or -excludedReferences parameters to create the object
    -geo should be an hashtable of arrays @{"included"=@('Austria','Europe');"excluded"=@("US","Russia")}
    If you do not provide -deviceName or -token then it will return the object as a powershell object to the script
.Example
	New-BarracudaNGFNetworkObject -deviceName <hostname or ip> -devicePort 8443 -creds <powershell credentials> -Type generic -name <objectname> -included @(@{"entry"=@{ip="$($i)"}},@{"entry"=@{ip="$($i)"}},@{"entry"=@{ip="$($i)"}}) 
    $object = New-BarracudaCGFNetworkObject -name myObject -type generic -includedObjects $include_objects -excludedReferences "Internet" -geo $geos 
.Notes
v0.2
#>

Function New-BarracudaCGFNetworkObject {
    [cmdletbinding()]
#If none of these are supplied it returns the code

param(
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$deviceName,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$false)]
        [string] $token,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string] $devicePort=8443,

#below parameters are used to define the api path being used. contain settings for CC, forwarding or host ruleset.
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
        [switch]$ccglobal,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$false)]
        [switch]$sharedfw,

#above parameters can be considered stock over all general rules.

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$name,

        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("generic","singleIPv4Address","listIPv4Address","singleIPv4Network","listIPv4Network","hostname","singleIPv6Address","listIPv6Address","singleIPv6Network","listIPv6Network")] 
        [string]$type="generic",

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [array]$includedObjects=@(),

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [array]$includedReferences=@(),

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [array]$excludedObjects,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [array]$excludedReferences,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$color,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$false)]
        [int]$dnsLifetime=600,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$false)]
        [hashtable] $geo,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$comment

        
    )

    

#defines the URL to call
 <#   if($cc){
   
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
             $url = $url + "/shared-firewall/objects/networks"
        }else{
            $url = $url + "/firewall/objects/networks"
        }

        
    }else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/config/v1"
  <#      if($hostfirewall){
            $url = $url + "/box/firewall/objects/networks"
        }else{
            if($serviceName -and $virtualServer){
               $url = $url + "/servers/$($virtualServer)/services/$($serviceName)/firewall/objects/networks"
            }else{
            $url = $url + "/forwarding-firewall/objects/networks"

            }
          #  $url = $url + "/forwarding-firewall/objects/networks"
        }

        
    }#>
    If ($PSBoundParameters['Debug']) {
        $DebugPreference = 'Continue'
    }
    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    Write-Debug "Provide PSBoundParameters"

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
        Write-Debug "$($key) : $($value)"
    }
    
    #Void's anything we don't want
   # [Void]$PSBoundParameters.Remove("token")
    
    #Provides empty array if nothing provide.
    if(!$PSBoundParameters.ContainsKey("excluded")){
        $PSBoundParameters.Add("excluded",@())
    }
    if(!$includedObjects){
        $includedObjects = @()
        #$includedObjects = $includedObjects + @{entry=$includedObj}
    }


    if(!$excludedObjects){
        $excludedObjects = @()
        #$excludedObjects = $excludedObjects + @{entry=$excludedObj}
    }
    

    #builds the paramters to be posted
    $postParams = @{}
    if($PSBoundParameters.name){
    $postParams.Add("name",$name)
    }
    $postParams.Add("type",$type)
    if($PSBoundParameters.geo){
        $postParams.Add("geo",$PSBoundParameters.geo)
    }
    $postParams.Add("comment",$comment)


    #references need to be hashtables inside array
    ForEach($obj in $includedReferences){
        $includedObjects = $includedObjects + @{"references"=$obj}
    }

    #references need to be hashtables inside array
    ForEach($obj in $excludedReferences){
        $excludedObjects = $excludedObjects + @{"references"=$obj}
    }

    $postParams.Add("excluded",$excludedObjects)
    $postParams.Add("included",$includedObjects)
    
    #Converts to JSON
    $data = ConvertTo-Json $postParams -Depth 99
    
    
    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    #Inserts the tail of the API path to the parameters 
    $PSBoundParameters["context"] = "objects/networks"

    #builds the REST API path.
    $url = Set-RESTPath @PSBoundParameters

    Write-Debug $url
    Write-Debug $data

    if(!$deviceName -and !$token){
        return $postParams

    }else{

        
            try{
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing
            }catch [System.Net.WebException] {
                    $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                    Write-Error $results
                     
            }


    }

return $results
}