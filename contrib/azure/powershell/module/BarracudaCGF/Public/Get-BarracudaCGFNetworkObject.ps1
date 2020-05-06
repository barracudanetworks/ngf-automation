<#
.Synopsis
    Get's details of a Network Object or objects
.Description
    This will return a powershell object containing the results of the query for either a specific network object or all objects for either the Host 
	Firewall or the Forwarding Firewall when the Virtual Server and Service details are provided.
.Example
	This will return all objects for the Host Firewall
	$objects = Get-BarracudaCGFNetworkObject -device <hostname or ip> -token <mytoken> 
	This will return a single object for the Forwarding Firewall
	$object = Get-BarracudaCGFNetworkObject -device <hostname or ip> -token <mytoken> -networkObjectName Internet
    If working with Control Center then include the -cluster and -range parameters to edit the firewall via it's CC
    $object = Get-BarracudaCGFNetworkObject -device <hostname or ip> -devicePort 8443 -creds <powershell creds> -virtualServer S1 -serviceName NGFW -networkObjectName Internet -range 1 -cluster CCclustername
.Notes
v1.3 - updated for 8.0.1 
#>
Function Get-BarracudaCGFNetworkObject {
	    [cmdletbinding()]
param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string]$deviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string] $devicePort="8443",
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$networkObjectName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[switch]$cc,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[switch]$sharedfw,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$serviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$serverName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$range,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$cluster,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$box,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string] $token,
[switch]$notHTTPs
)

    #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }

    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    <#
    if($range -and $cluster){
          $url_insert = "/cc/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/"
    }elseif($range -and $cluster -and $box){
        $url_insert = "/cc/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/boxes/$($PSBoundParameters.("box"))/"
    }

    
    #Adjusts URL if either a Virtual Server is supplied or a networkObjectName
    if($PSBoundParameters.ContainsKey("Server") -and $PSBoundParameters.ContainsKey("networkObjectName")){
       $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)servers/$($virtualServer)/services/$($serviceName)/objects/networks/$($networkObjectName)" 
    }elseif($PSBoundParameters.ContainsKey("virtualServer")){
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)servers/$($virtualServer)/services/$($serviceName)/objects/networks"
    }elseif($PSBoundParameters.ContainsKey("networkObjectName")){
         $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)objects/networks/$($networkObjectName)"
    }
    else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)objects/networks"
    }

    #>

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
             $url = $url + "/shared-firewall/objects/networks/$($networkObjectName)"
        }else{
            $url = $url + "/firewall/objects/networks/$($networkObjectName)"
        }
    }else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/config/v1"
        if(!$ServerName){
            $url = $url + "/box/firewall/objects/networks/$($networkObjectName)"
        }elseif($ServerName){
            $url = $url + "/forwarding-firewall/objects/networks/$($networkObjectName)"
        }
    }
    
    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Output $PSBoundParameters
        Write-Output $url
        try{
			$results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method Get -Headers $header -UseBasicParsing -Debug 
			if((ConvertFrom-Json $results.Content).objects){
		        return (ConvertFrom-Json $results.Content).objects
            }else{
                return ConvertFrom-Json $results.Content
            }
        }catch{
            Write-Output $_.Exception.Message
        }
    }else{
        try{
			$results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method Get -Headers $header -UseBasicParsing
            if((ConvertFrom-Json $results.Content).objects){
		        return (ConvertFrom-Json $results.Content).objects
            }else{
                return ConvertFrom-Json $results.Content
            }
        }catch{
            Write-Output $_.Exception.Message
			#Write-Output $PSBoundParameters
			Write-Output $url
        }
    }

return $results
}
