<#
.Synopsis
    Gets general info about the CGF, including load, memory usage, uptime, model, serial and release
.Description
    This will return a powershell object containing general information about the FW, it can be used to query things like CPU load or Memory usage or uptime.
.Example
	This will return the status of the FW on the default API port using HTTPS
	$objects = Get-BarracudaCGFInfo -device <hostname or ip> -token <tokenstring>

.Notes
v0.1 - created for 8.0.1
#>
Function Get-BarracudaCGFInfo{

param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string]$deviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string] $devicePort="8443",
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
		$results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/info" -Method GET -Headers $header -UseBasicParsing 
	}catch{
		Write-Error("Unable to Login to API http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/info due to " + $_.Exception)
	}
		

return ConvertFrom-Json $results.Content
}