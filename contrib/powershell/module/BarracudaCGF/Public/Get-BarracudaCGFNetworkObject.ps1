<#
.Synopsis
    Get's details of a Network Object or objects
.Description
    This will return a powershell object containing the results of the query for either a specific network object or all objects for either the Host 
	Firewall or the Forwarding Firewall when the Virtual Server and Service details are provided.
.Example
	This will return all objects for the Host Firewall
	$objects = Get-BarracudaCGFNetworkObject -device <hostname or ip> -token <mytoken> 
	This will return a single object for the Forwarding Firewall
	$object = Get-BarracudaCGFNetworkObject -device <hostname or ip> -token <mytoken> -networkObjectName Internet
    If working with Control Center then include the -cluster and -range parameters to edit the firewall via it's CC
    $object = Get-BarracudaCGFNetworkObject -device <hostname or ip> -devicePort 8443 -creds <powershell creds> -virtualServer S1 -serviceName NGFW -networkObjectName Internet -range 1 -cluster CCclustername
.Notes
v1.3 - updated for 8.0.1 
#>
Function Get-BarracudaCGFNetworkObject {
	    [cmdletbinding()]
param(
#below parameters are about the connection to the API
[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string] $token,

[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
$creds,

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
[switch]$sharedfw,

#above parameters can be considered stock over all general rules.

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$objectName,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[switch]$details

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

        #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    #Inserts the tail of the API path to the parameters 
    $PSBoundParameters["context"] = "objects/networks"

    #builds the REST API path.
    $url = Set-RESTPath @PSBoundParameters

    #Provide a specific object
    if($objectName){
        $url = $url + "/$($PSBoundParameters.("objectName"))"
    }
    
    #Provide additional details of objects
    if($details){

        $url = $url + "?expand=true"
    }
    
    
    if(!$deviceName -and !$token){
        Write-Error "No device or token provided!"

    }else{
        try{
			if($creds){
		        $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method Get -Headers $header -Credential $creds -UseBasicParsing 
            }else{
                $header = @{"X-API-Token" = "$token"}
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method Get -Headers $header -UseBasicParsing
            }
            if((ConvertFrom-Json $results.Content).objects){
		        return (ConvertFrom-Json $results.Content).objects
            }else{
                return ConvertFrom-Json $results.Content
            }
        }catch{
            Write-Output $_.Exception.Message
			#Write-Output $PSBoundParameters
			Write-Output $url
        }
    }

return $results
}
