
<#
.Synopsis
	Gets a list of firewall rules within a list or a specific firewall rule in a list
.Description
	This function will collect a list of the firewall rules present in a firewall rule list, with the expand option set to true it will provide full details of all the rules.
	This can be used to find a position within an existing ruleset to create a new rule, or just provide reporting.
.Example
	Get-BarracudaCGFFirewallRule -deviceName $dev_name -token $token -expand $true
	Get-BarracudaCGFFirewallRule -deviceName $dev_name -token $token -list "MyRuleList" 
.Notes
v0.1
#>
Function Get-BarracudaCGFFirewallRule {
    [cmdletbinding()]
param(
#These are the general access parameters
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
ValueFromPipelineByPropertyName=$false)]
[switch]$sharedfw,

#The following parameters are for the position of the rule in ruleset

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[switch]$details,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$listname,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[switch]$list

)

     If ($PSBoundParameters['Debug']) {
        $DebugPreference = 'Continue'
    }

    Write-Debug "Provide PSBoundParameters Get-BarracudaCGFFirewallRule" 

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
        Write-Debug "$($key) : $($value)"
    }



    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    #Inserts the tail of the API path to the parameters 
    $PSBoundParameters["context"] = "rules"

    #builds the REST API path.
    $url = Set-RESTPath @PSBoundParameters

    #expansion after all other paths.
    if($details){
        $url = $url + "?expand=true"
    }else{
        $url = $url +  "?expand=false"
    }



    #Write-Debug $postParams
    Write-Debug $url
        
        try{
            if($creds){
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method GET -Headers $header -Body $data -Credential $creds -UseBasicParsing
            }else{
                #Sets the token header
                $header = @{"X-API-Token" = "$token"}
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method GET -Headers $header -Body $data -UseBasicParsing
            }
        }catch [System.Net.WebException] {
                $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                Write-Error $results
                throw   
            }



return ConvertFrom-Json $results.content
}