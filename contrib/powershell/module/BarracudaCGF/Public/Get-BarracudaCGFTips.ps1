<#
.Synopsis
    Gets any tips published to the CGF, for example product updates that should be applied
.Description
    This will return a powershell object containing any tips presented to the FW
.Example
	This will return the status of the FW on the default API port using HTTPS
	$objects = Get-BarracudaCGFTips -device <hostname or ip> -token <tokenstring>

.Notes
v0.1 - created for 8.0.1 
#>
Function Get-BarracudaCGFTips{
	    [cmdletbinding()]
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
		$results =Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/tips" -Method GET -Headers $header -UseBasicParsing 
	}catch{
		Write-Error("Unable to Login to API http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/tips due to " + $_.Exception)
	}
		

    $tips = ConvertFrom-Json $results.Content
    $cleanresult = @{}
    $i=0
    ForEach($tip in $tips){
    $i++
    
        $tiptitle = $tip.content.Substring($tip.content.IndexOf("<h2>"),($tip.content.IndexOf("</h2>")-$tips.content.IndexOf("<h2>"))).Replace("<h2>","").Replace("</h2>","")
        $tiptxt = $tip.content.Substring($tip.content.IndexOf("<p>"),($tip.content.IndexOf("</body>")-$tip.content.IndexOf("<p>"))).Replace("<p>","").Replace("</p>","")
    
        $cleanresult.add($i, @{"title"="$($tiptitle)";"text"="$($tiptxt)"})
   

}


return $cleanresult
}