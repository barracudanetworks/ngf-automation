<#
.Synopsis
	Creates a new service object in the firewall or returns a suitable powershell object for use with New-BarracudaCGFFirewallRule to create an explicit object
.Description
    This function will create a new service object in either the Host Firewall or Forwarding Firewall or return a powershell object. It expects input of either the -entries or -references to create an object.
    -entries is hashtable that you can use Convert-BarracudaCGFServiceObject-ps1 to create from CSV.

.Example
	New-BarracudaCGFServiceObject -deviceName $dev_name -token $token -name "MyObject" -entries $array -Debug -Verbose 
    $object = New-BarracudaCGFServiceObject -name "MyObject" -entries $array 
.Notes
v0.1
#>

Function New-BarracudaCGFServiceObject {
[cmdletbinding()]
param(
#below parameters are about the connection to the API
[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$false)]
[string] $token,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string] $devicePort=8443,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$notHTTPs,

#below parameters are used to define the api path being used. contain settings for CC, forwarding or host ruleset.
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$virtualServer,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$serviceName,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$range,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$cluster,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$box,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$hostfirewall,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$ccglobal,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$fwdingfw,

#above parameters can be considered stock over all general rules.

# the below parameters define the object

[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[string]$name,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[array]$entries=@(),

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[array] $references,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$comment,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$color

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
    $postParams.Add("name",$name)
    $postParams.Add("comments",$comments)


        #references need to be hashtables inside array
        ForEach($obj in $references){
            $entries = $entries += @{"references"=$obj}
        }
    
    $postParams.Add("entries",$entries)
    
    $data = ConvertTo-Json $postParams -Depth 99
    
    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    #Inserts the tail of the API path to the parameters 
    $PSBoundParameters["context"] = "objects/services"

    #builds the REST API path.
    $url = Set-RESTPath @PSBoundParameters

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