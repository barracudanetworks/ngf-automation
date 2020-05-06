<#
.Synopsis
	Creates a new service object in the firewall or returns a suitable powershell object for use with New-BarracudaCGFFirewallRule to create an explicit object
.Description
    This function will create a new service object in either the Host Firewall or Forwarding Firewall or return a powershell object. It expects input of either the -entries or -references to create an object.
    -entries is hashtable that you can use Convert-BarracudaCGFServiceObject-ps1 to create from CSV.

.Example
	New-BarracudaCGFServiceObject -deviceName $dev_name -token $token -name "MyObject" -entries $array -Debug -Verbose 
    $object = New-BarracudaCGFServiceObject -name "MyObject" -entries $array 
.Notes
v0.1
#>

Function New-BarracudaCGFServiceObject {
[cmdletbinding()]
param(
#if no device details are provided a powershell object is created.
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,

[Parameter(Mandatory=$false,
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
ValueFromPipelineByPropertyName=$false)]
[switch]$notHTTPs,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$hostfirewall,


# Below are the values that define the object

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[string]$name,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[array]$entries=@(),

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[array] $references,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$comment,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$color


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
             $url = $url + "/shared-firewall/objects/services"
        }else{
            $url = $url + "/firewall/objects/services"
        }
    }else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/config/v1"
        if($hostfirewall){
            $url = $url + "/box/firewall/objects/services"
        }else{
            $url = $url + "/forwarding-firewall/objects/services"
        }
    }

    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Verbose $PSBoundParameters
    }

    
    $postParams = @{}
    $postParams.Add("name",$name)
    $postParams.Add("comments",$comments)


        #references need to be hashtables inside array
        ForEach($obj in $references){
            $entries = $entries += @{"references"=$obj}
        }
    
    $postParams.Add("entries",$entries)
    
    $data = ConvertTo-Json $postParams -Depth 99
    
    
    if(!$deviceName -and !$token){
        return $postParams

    }else{
      
        if($PSBoundParameters.ContainsKey("Debug")){
            Write-Debug $postParams
            Write-Debug $url
            Write-Debug $data

            try{
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing -Debug
            }catch [System.Net.WebException] {
                    $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                    Write-Error $results
                    throw   
                }
        }else{
        
            try{
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing
            }catch [System.Net.WebException] {
                    $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                    Write-Error $results
                    throw   
                }

        }
    }

return $results
}