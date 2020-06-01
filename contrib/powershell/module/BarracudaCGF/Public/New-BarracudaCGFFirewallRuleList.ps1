
<#
.Synopsis
	Creates a new firewall rulelist
.Description
    This function will create a new network object in either the Host Firewall or Forwarding Firewall. It expects input of either the -included, excluded, includedReferences or -excludedReferences parameters to create the object
    -geo should be an hashtable of arrays @{"included"=@('Austria','Europe');"excluded"=@("US","Russia")}
.Example
	New-BarracudaCGFFirewallRuleList -deviceName $barracudacc -token $barracudacctoken -range 1 -cluster $cluster -box $box -serviceName $servicename -listname "Bob" -Debug

.Notes
v0.1
#>

Function New-BarracudaCGFFirewallRuleList {
[cmdletbinding()]
param(
#These are the general access parameters
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

#the below define where the rule is created host or forwarding, cc or local.

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
ValueFromPipelineByPropertyName=$true)]
[string]$listname

)

   

    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    if($PSBoundParameters.ContainsKey("Debug")){
    #Note - the function will return any values in the pipeline, so always use Write-Host 
        Write-Verbose $PSBoundParameters
    }

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
    }
    
 

    $data = ConvertTo-Json @{"name"="$($listname)"} -Depth 99
    
        #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    #Inserts the tail of the API path to the parameters 
    $PSBoundParameters["context"] = "rules"

    #builds the REST API path.
    [string]$url = Set-RESTPath @PSBoundParameters
    $url = $url.Replace("$($listname)","")


        Write-Debug $url
        Write-Debug $data

        
        try{

            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing
        }catch [System.Net.WebException] {
                $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                Write-Error $results
                throw   
            }



return $results
}