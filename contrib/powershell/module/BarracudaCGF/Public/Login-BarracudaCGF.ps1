Function Login-BarracudaCGF {
	    [cmdletbinding()]
param(
#below parameters are about the connection to the API
[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string] $token,

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$false)]
[string] $username,

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$false)]
[string] $password,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string] $devicePort=8443,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$notHTTPs


)
 


    If ($PSBoundParameters['Debug']) {
        $DebugPreference = 'Continue'
    }

    Write-Debug "Provide PSBoundParameters" 

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
        Write-Debug "$($key) : $($value)"
    }

    
    $postParams = @{}
    $postParams.Add("username",$name)
    $postParams.Add("password",$comments)
    
    $data = ConvertTo-Json $postParams -Depth 99
    
    #Sets the token header
    #$header = @{"X-API-Token" = "$token"}
    $url = "http$($s)://$($deviceName):$($devicePort)/rest/auth/v1/login"

    #Write-Debug $postParams
    Write-Debug $url
    Write-Debug $data

    if(!$deviceName -and !$token){
        return $postParams

    }else{
        
            try{
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing 
            }catch [System.Net.WebException] {
                    $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                    Write-Error $results
                   
                }

    }

return $results
}