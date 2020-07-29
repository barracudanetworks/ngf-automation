Function Get-BarracudaCCRanges{
<#
.Synopsis
    Gets the status of the CGF
.Description
    This will return a powershell object containing the status of the FW
.Example
	This will return the status of the FW on the default API port using HTTPS
	$objects = Get-BarracudaCGFNetworkObject -device <hostname or ip> -token <tokenstring>

.Notes
v0.1 - created for 8.0.1
#>
param(
[cmdletbinding()]
[Parameter(Mandatory=$true,
    ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,
[Parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
[int] $devicePort=8443,
[Parameter(Mandatory=$true,
    ValueFromPipelineByPropertyName=$true)]
[string] $token,
[Parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
[switch]$notHTTPs
)

    #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }

    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    try{

           	$results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/cc/v1/ranges" -Method GET -Headers $header -UseBasicParsing
       
	}catch [System.Net.WebException] {
                $Error[0] | Get-ExceptionResponse
                throw   
            }
		

return ConvertFrom-Json $results.Content
}