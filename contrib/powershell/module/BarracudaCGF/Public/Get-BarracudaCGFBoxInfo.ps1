<#
.Synopsis
    Gets general info about the CGF, including load, memory usage, uptime, model, serial and release
.Description
    This will return a powershell object containing general information about the FW, it can be used to query things like CPU load or Memory usage or uptime.
    Additional use of the dataon parameter will provide read only information upon.
    info
    motd - message of the day
    licenses
    hostids
    licensevalues
    securitysubscriptions
    versions
    info
    tips
    services
    admins
    sessions

.Example
	This will return the status of the FW on the default API port using HTTPS
	$objects = Get-BarracudaCGFInfo -device <hostname or ip> -token <tokenstring>
    $services = GetBarracudaCGFBoxInfo -device <hostname or ip> -creds <PSCredentialObject> -subject "services"
.Notes
v0.1 - created for 8.0.1
#>
Function Get-BarracudaCGFBoxInfo{

param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[string]$deviceName,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string] $devicePort="8443",
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[string] $token,
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
$creds,
#Decide what extra info to provide.
[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
[ValidateSet("info","motd","hostids","licenses","licensevalues","securitysubscriptions","versions","info","tips","services","admins","sessions")] 
$subject,
[switch]$notHTTPs
)

    #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }

    

	try{
        if($creds){
		    $results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/$($subject)" -Method GET -Headers $header -Credential $creds -UseBasicParsing 
        }else{
            $header = @{"X-API-Token" = "$token"}
            $results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/$($subject)" -Method GET -Headers $header -UseBasicParsing 
        }
	}catch{
		Write-Error("Unable to Login to API http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/$($subject) due to " + $_.Exception)
	}
		

return ConvertFrom-Json $results.Content
}