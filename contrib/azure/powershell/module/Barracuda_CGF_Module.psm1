Function Config-TLSSettings{
param(
[switch]$allowSelfSigned,
[switch]$noCRL
)
#Enables TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12
	if($allowSelfSigned){
	#May be required for self signed cert checks to pass.
		[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
	}
	if($noCRL){
	#May be required to ignore CRLs
		[Net.ServicePointManager]::CheckCertificateRevocationList = { $false }
	}
}

Function Get-BarracudaCGFNetworkObject {
<#
.Synopsis
    Get's details of a Network Object or objects
.Description
    This will return a powershell object containing the results of the query for either a specific network object or all objects for either the Host 
	Firewall or the Forwarding Firewall when the Virtual Server and Service details are provided.
.Example
	This will return all objects for the Host Firewall
	$objects = Get-BarracudaCGFNetworkObject -device <hostname or ip> -devicePort 8443 -creds <powershell creds> 
	This will return a single object for the Forwarding Firewall
	$object = Get-BarracudaCGFNetworkObject -device <hostname or ip> -devicePort 8443 -creds <powershell creds> -virtualServer S1 -serviceName NGFW -networkObjectName Internet
    If working with Control Center then include the -cluster and -range parameters to edit the firewall via it's CC
    $object = Get-BarracudaCGFNetworkObject -device <hostname or ip> -devicePort 8443 -creds <powershell creds> -virtualServer S1 -serviceName NGFW -networkObjectName Internet -range 1 -cluster CCclustername
.Notes
v1.2 - updated for CC 
#>
param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string]$deviceName,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string] $devicePort,
$creds,[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$virtualServer,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$serviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$networkObjectName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$range,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$cluster,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$box,
[switch]$notHTTPs
)
	#makes the connection HTTPS
	if(!$notHTTPS){
		$s = "s"
	}

    $url_insert = "/"

    if($range -and $cluster){
          $url_insert = "/cc/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/"
    }elseif($range -and $cluster -and $box){
        $url_insert = "/cc/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/boxes/$($PSBoundParameters.("box"))/"
    }

    #Adjusts URL if either a Virtual Server is supplied or a networkObjectName
    if($PSBoundParameters.ContainsKey("virtualServer") -and $PSBoundParameters.ContainsKey("networkObjectName")){
       $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)servers/$($virtualServer)/services/$($serviceName)/objects/networks/$($networkObjectName)" 
    }elseif($PSBoundParameters.ContainsKey("virtualServer")){
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)servers/$($virtualServer)/services/$($serviceName)/objects/networks"
    }elseif($PSBoundParameters.ContainsKey("networkObjectName")){
         $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)objects/networks/$($networkObjectName)"
    }
    else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)objects/networks"
    }

    
    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Output $PSBoundParameters
        Write-Output $url
        try{
			$results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method Get -Credential $creds -Debug 
			$results = (ConvertFrom-Json $results.Content)
        }catch{
            Write-Output $_.Exception.Message
        }
    }else{
        try{
			$results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method Get -Credential $creds
			$results = (ConvertFrom-Json $results.Content)
        }catch{
            Write-Output $_.Exception.Message
			#Write-Output $PSBoundParameters
			Write-Output $url
        }
    }

return $results
}

Function Get-BarracudaCGFVirtualServers {
	<#
.Synopsis
    Collects the names of the Virtual Servers
.Description
    This will return a list of Virtual Servers running on the queried firewall
.Example
	Get-BarracudaNGFVirtualServers -deviceName <hostname or ip> -devicePort 8443 -creds <powershell credentials> 

.Notes
v1.0
#>
param(
[string]$deviceName,
$devicePort=8443,
[switch]$notHTTPs,
$creds
)

	#makes the connection HTTPS
	if(!$notHTTPS){
		$s = "s"
	}

    try{
        $results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/servers" -ContentType 'application/json' -Method Get -Credential $creds -UseBasicParsing
		$results = (ConvertFrom-Json $results.Content)
    }catch{
        Write-Output $_.Exception.Message
    }
return $results.servers
}

Function Get-BarracudaCGFServerServices {
<#
.Synopsis
    Collects the names of the Services
.Description
    This will return a list of Services running on the queried firewall under the Virtual Server provided
.Example
	Get-BarracudaNGFServerServices -deviceName <hostname or ip> -devicePort 8443 -creds <powershell credentials> -virtualServerName S1

.Notes
v1.0
#>
param(
[string]$deviceName,
[string] $devicePort,
$creds,
[string]$virtualServerName,
[switch]$notHTTPs
)
	#makes the connection HTTPS
	if(!$notHTTPS){
		$s = "s"
	}
    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Output $PSBoundParameters
    }
    try{
        $results = Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/servers/$($virtualServerName)/services" -ContentType 'application/json' -Method Get -Credential $creds -UseBasicParsing
		$results = (ConvertFrom-Json $results.Content)
	}catch{
        Write-Output $_.Exception.Message
		Write-Output $PSBoundParameters
		Write-Output $url
	
    }
return $results.services
}



Function New-BarracudaNetObject{
<#
.Synopsis
	Takes input in the form of a CSV, list or single IP and converts into an array suitable for use with New-BarracudaNGFNetworkObject
.Description
    This function can be used to create a suitable array to be used with the New-BarracudaNGFNetworkObject command as either the included or excluded IP's 
	for the network object creation. 
	At this time all objects inputted should be of the same type. 
	The input is expected to be in normal notation e.d 10.2.3.0/24 and will be converted by the function to phion notation 10.2.3.0/8 
	This will create an array like; @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'})
	From a CSV in the format;
	type, addresses
	ipV4, 10.7.3.0/24
	ipV4, 10.7.4.0/24
	Or a simple list seperated by , or a powershell Array''
.Example
	New-BarracudaNGFObject -objectType ipV4 -objectValue 10.2.1.3
	New-BarracudaNGFObject -objectType ipV4 -csvFileName C:\myfile.csv


.Notes
	Handles IPv4 and IPv6
	added -old which should be enabled if the subnet masks do not appear correctly in the FW. Older API releases did not convert to a reverse mask. v7.2 and up do not need this. 
#>
param(
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("ipV4", "rangeV4", "networkV4", "ipV6", "reference")]  
[string]$objectType,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$objectValue,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
$csvFileName,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
$objectList,
[switch]$old
)


    $array=@()
	if($old){
		switch($objectType){
			"ipV4" {
				if($csvFile){
					ForEach($item in (ConvertFrom-CSV (Get-Content $csvFileName))){
						$array = $array += @{type="$($item.type)";$item.type="$($item.address.Split('/')[0])/$(32-$item.address.Split('/')[1])"}
					}
				}elseif($objectList){
					ForEach($item in $objectList){
						$array = $array += @{type=$objectType;$objectType="$($item.Split('/')[0])/$(32-$item.Split('/')[1])"}
					}
				}else{
						$hashtable = @{type="$objectType";$objectType="$($objectValue.Split('/')[0])/$(32-$objectValue.Split('/')[1])"}
				}
			}
			"ipv6" {
				if($csvFile){
					ForEach($item in (ConvertFrom-CSV (Get-Content $csvFileName))){
						$array = $array += @{type="$($item.type)";$item.type="$($item.address)"}
					}
				}elseif($objectList){
					ForEach($item in $objectList){
						$array = $array += @{type=$objectType;$objectType="$($item)"}
					}
				}else{
						$hashtable = @{type="$objectType";$objectType="$($objectValue)"}
				}
			}
			default{}
		}
	}else{
		switch($objectType){
			"ipV4" {
				ForEach($i in $objectList){
						$array = $array += @{type="ipV4";ipV4="$($i)"}
				}
			}
			"ipV6" {
				ForEach($i in $objectList){
						$array = $array += @{type="ipV6";ipV6="$($i)"}
				}
			}
		}
	}

return $array
}

Function New-BarracudaCGFNetworkObject {
<#
.Synopsis
	Creates a new network object
.Description
    This function will create a new network object in either the Host Firewall or Forwarding Firewall, it expects the values in included and excluded to be an array 
	containing a hashtable describing the value and type.
	Either an array @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'}) or a variable created using New-BarracudaNGFObject 

.Example
	New-BarracudaNGFNetworkObject -deviceName <hostname or ip> -devicePort 8443 -creds <powershell credentials> -Type generic -name <objectname> -included @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'},@{'type'='ipV4';'ipV4'='13.67.154.0/24'}) 
.Notes
v1.0
#>
param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string]$deviceName,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string] $devicePort,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
$creds,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$virtualServer,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$serviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$name,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[array]$included,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[array]$excluded,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[ValidateSet("generic", "ipSingle", "ipList", "netSingle", "netList", "hostname", "ip6Single", "ip6List", "net6Single", "net6List")]  
[string]$type,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$comments,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$rcsMessage,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$overrideSharedObject="false",
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$range,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$cluster,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$box,
[switch]$notHTTPs
)
	#makes the connection HTTPS
	if(!$notHTTPS){
		$s = "s"
        Config-TLSSettings
	}

    $url_insert = "/"

    if($range -and $cluster){
         $url_insert = "/cc/ranges/$($range)/clusters/$($cluster)/"
         
    }elseif($range -and $cluster -and $box){
        $url_insert = "/cc/ranges/$($range)/clusters/$($cluster)/boxes/$($box)/"
    }

    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Output $PSBoundParameters
    }

        #Adjusts URL if either a Virtual Server is supplied or a networkObjectName
    if($PSBoundParameters.ContainsKey("virtualServer")){
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)servers/$($virtualServer)/services/$($serviceName)/objects/networks"
    }elseif($PSBoundParameters.ContainsKey("networkObjectName")){
         $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)objects/networks/$($networkObjectName)"
    }
    else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)objects/networks"
    }

 
    #removed the items we don't need to build the json
    [Void]$PSBoundParameters.Remove("deviceName")
    [Void]$PSBoundParameters.Remove("devicePort")
    [Void]$PSBoundParameters.Remove("notHTTPS")
    [Void]$PSBoundParameters.Remove("virtualServer")
    [Void]$PSBoundParameters.Remove("serviceName")
    [Void]$PSBoundParameters.Remove("range")
    [Void]$PSBoundParameters.Remove("cluster")
    [Void]$PSBoundParameters.Remove("box")
    [Void]$PSBoundParameters.Remove("creds")
    if(!$PSBoundParameters.ContainsKey("excluded")){
        $PSBoundParameters.Add("excluded",@())
    }
    if(!$PSBoundParameters.ContainsKey("included")){
        $PSBoundParameters.Add("included",@())
    }
   
    if($PSBoundParameters.ContainsKey("Debug")){
        [Void]$PSBoundParameters.Remove("Debug")
        Write-Output $PSBoundParameters
        $data = ConvertTo-Json $PSBoundParameters 

       Write-Output $url
       Write-Output $data

        try{
            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Credential $creds -Body $data -UseBasicParsing -Debug
        }catch{
            
			if($_.Exception.Response.StatusCode.value__ -ne 409){
				Get-BarracudaCGF-ResultMessage $_.Exception.Response.StatusCode.value__
				Write-Error $_.Exception.Message
				#Write-Output $PSBoundParameters
				Write-Output $url
			}else{
				$results = $_.Exception.Response.StatusCode.value__
			}
            
        }
    }else{
        $data = ConvertTo-Json $PSBoundParameters
        try{
            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Credential $creds -Body $data -UseBasicParsing
        }catch{
            
            if($_.Exception.Response.StatusCode.value__ -ne 409){
				Get-BarracudaCGF-ResultMessage $_.Exception.Response.StatusCode.value__
			}else{
				$results = $_.Exception.Response.StatusCode.value__
			}
        }

    }

return $results
}


Function Update-BarracudaCGFNetworkObject {
<#
.Synopsis
	Updates an existing network object
.Description
    This function will update a network object in either the Host Firewall or Forwarding Firewall, it can be ran either as a complete replacement or partial changes.
    
    it expects the values in included and excluded to be an array 
	containing a hashtable describing the value and type.
	Either an array @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'}) or a variable created using New-BarracudaNGFObject 
    If working with Control Center then include the -cluster and -range parameters to edit the firewall via it's CC

.Example
	New-BarracudaNGFNetworkObject -deviceName <hostname or ip> -devicePort 8443 -creds <powershell credentials> -Type generic -name <objectname> -included @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'},@{'type'='ipV4';'ipV4'='13.67.154.0/24'}) 

.Notes
v1.0
#>
param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string]$deviceName,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string] $devicePort,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
$creds,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$virtualServer,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$serviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$name,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[array]$included,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[array]$excluded,
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[ValidateSet("generic", "ipSingle", "ipList", "netSingle", "netList", "hostname", "ip6Single", "ip6List", "net6Single", "net6List")]  
[string]$type,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$comments,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$rcsMessage,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[switch]$replace,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$range,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$cluster,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string]$box,
[switch]$notHTTPs
)
	#makes the connection HTTPS
	if(!$notHTTPS){
		$s = "s"
	}

    $url_insert = "/"

    if($range -and $cluster){
         $url_insert = "/cc/ranges/$($range)/clusters/$($cluster)/"
         
    }elseif($range -and $cluster -and $box){
        $url_insert = "/cc/ranges/$($range)/clusters/$($cluster)/boxes/$($box)/"
    }

    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Output $PSBoundParameters
    }

        #Adjusts URL if either a Virtual Server is supplied or a networkObjectName
    if($PSBoundParameters.ContainsKey("virtualServer")){
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)servers/$($virtualServer)/services/$($serviceName)/objects/networks/$($name)"
    }else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/firewall/v1$($url_insert)objects/networks/$($name)"
    }

    #removed the items we don't need to build the json
    [Void]$PSBoundParameters.Remove("deviceName")
    [Void]$PSBoundParameters.Remove("devicePort")
    [Void]$PSBoundParameters.Remove("notHTTPS")
     [Void]$PSBoundParameters.Remove("virtualServer")
    [Void]$PSBoundParameters.Remove("serviceName")
    [Void]$PSBoundParameters.Remove("creds")
        [Void]$PSBoundParameters.Remove("range")
    [Void]$PSBoundParameters.Remove("cluster")
    [Void]$PSBoundParameters.Remove("box")
    if(!$PSBoundParameters.ContainsKey("excluded")){
        $PSBoundParameters.Add("excluded",@())
    }
    if(!$PSBoundParameters.ContainsKey("included")){
        $PSBoundParameters.Add("included",@())
    }
    if($PSBoundParameters.ContainsKey("replace")){
        [Void]$PSBoundParameters.Remove("replace")
    }

   
    if($PSBoundParameters.ContainsKey("Debug")){
        [Void]$PSBoundParameters.Remove("Debug")
        Write-Output $PSBoundParameters
        $data = ConvertTo-Json $PSBoundParameters 

        Write-Output $url
        Write-Output $data
        try{
            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method PUT -Credential $creds -Body $data -UseBasicParsing -Debug
        }catch{
            
            
            Get-BarracudaCGF-ResultMessage $_.Exception.Response.StatusCode.value__
			Write-Error $_.Exception.Message
			#Write-Output $PSBoundParameters
			Write-Output $url
		
            }
        
    }else{
        $data = ConvertTo-Json $PSBoundParameters
        try{
            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method PUT -Credential $creds -Body $data -UseBasicParsing
			
        }catch{

			Get-BarracudaCGF-ResultMessage $_.Exception.Response.StatusCode.value__
			Write-Error $_.Exception.Message
        }
        

    }

return $results.StatusCode
}


Function  Get-BarracudaCGF-ResultMessage{
<#
.Synopsis
	Provides custom messages when API returns results
.Description
    This function is given the input of a HTTP statusCode and returns a printed message to screen/log for that result.

.Example
	GET-BarracudaCGF-ResultMessage 204 
.Notes
v1.0
#>
param(
$results,
$objectname
)
    switch($results){
		"500" { Write-Error "Unable to add entry, check if service is already locked or incorrectly named"; break}
		"403" { Write-Error "Authorisation failed"; break}
		"409" { Write-Output "Existing newtork object found - Replacing object instead"; break	}
		"204" { Write-Output "$($objectname) updated succesfully"; break }
		{$_ -ge 200 -or $_ -le 299} { Write-Output "$($objectname) updated succesfully"; break }
	    default{	 Write-Output "$($results)"; break;       }
		}


}