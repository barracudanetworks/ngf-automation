<#
.Synopsis
    Gets the connection Message for the CGF
.Description
    Like when you connect to the SSH session this will print out the message board
.Example
	This will return the status of the FW on the default API port using HTTPS
	$objects = Get-BarracudaCGFMessageBoard -device <hostname or ip> -token <tokenstring>

.Notes
v0.1 - created for 8.0.1 
#>
Function Get-BarracudaCGFMessageBoard{
	    [cmdletbinding()]
param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string]$deviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string] $devicePort="8443",
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string] $token,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
$creds,
[switch]$notHTTPs
)

    #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }

    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

	try{
        if($creds){
		    $results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/motd" -Method GET -Headers $header -Credential $creds -UseBasicParsing 
        }else{
            $header = @{"X-API-Token" = "$token"}
		    $results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/motd" -Method GET -Headers $header -UseBasicParsing 
        }
	}catch{
		Write-Error("Unable to Login to API http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/motd due to " + $_.Exception)
	}
		

return ConvertFrom-Json $results.Content
}