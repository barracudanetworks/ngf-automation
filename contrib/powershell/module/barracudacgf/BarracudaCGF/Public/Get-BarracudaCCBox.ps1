Function Get-BarracudaCCBox{
<#
.Synopsis
    Collects a list of boxes from control center
.Description
    This will return a powershell object containing a list of boxes
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
[Parameter(Mandatory=$true,
    ValueFromPipelineByPropertyName=$true)]
[int]$range,
[Parameter(Mandatory=$true,
    ValueFromPipelineByPropertyName=$true)]
[string]$cluster,
[Parameter(Mandatory=$true,
    ValueFromPipelineByPropertyName=$true)]
[string]$box,
[Parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
[ValidateSet("zerotouchconfig", "configupdates", "licensestatus", "zerotouchstatus", "statusmap")]
[string]$detailsof,
<#
[Parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
[switch]$configupdates,
[Parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
[switch]$licensestatus,
#>
[Parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
[switch]$notHTTPs
)

    #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }

    switch($detailsof){
    "zerotouchconfig" {$getextra = "/zerotouch/configurations"}
    "configupdates" {$getextra = "/zerotouch/configurations"} 
    "licensestatus" {$getextra = "/licenses/status"} 
    "zerotouchstatus" {$getextra = "/zerotouch/statusmap"} 
    "statusmap" {$getextra = "/statusmap"}
    }

    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    try{
           	$results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/cc/v1/ranges/$($range)/clusters/$($cluster)/boxes/$($box)$($getextra)" -Method GET -Headers $header -UseBasicParsing
       
	}catch [System.Net.WebException] {
                $Error[0] | Get-ExceptionResponse
                throw   
            }
		

return ConvertFrom-Json $results.Content
}