	<#
.Synopsis
    Collects the names of the Virtual Servers
.Description
    This will return a list of Virtual Servers running on the queried firewall
.Example
	Get-BarracudaNGFServers -deviceName <hostname or ip> -token <apitoken> 

.Notes
v1.0
#>



Function Get-BarracudaCGFServers {
	    [cmdletbinding()]
param(
[string]$deviceName,
$devicePort=8443,
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


    try{
        $results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/servers" -ContentType 'application/json' -Method GET -Headers $header -UseBasicParsing
		$results = (ConvertFrom-Json $results.Content)
    }catch{
        Write-Output $_.Exception.Message
    }
return $results.servers
}
