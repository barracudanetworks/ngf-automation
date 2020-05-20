
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




    <#
#defines the URL to call
    if($cc){
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/cc/v1/config"
        
        if($range -and $cluster -and $serverName -and $serviceName){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/servers/$($PSBoundParameters.("serverName"))/services/$($PSBoundParameters.("serviceName"))"
        }elseif($range -and $cluster -and $box){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/boxes/$($PSBoundParameters.("box"))"
        }elseif($range -and $cluster -and $serviceName){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/services/$($PSBoundParameters.("serviceName"))"
        }elseif($range -and $cluster){
              $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))"
        }elseif($range){
            $url = $url + "/ranges/$($PSBoundParameters.("range"))"
        }
        else{
        #assume global
            $url = $url + "/global"
        }
        if($sharedfw){
             $url = $url + "/shared-firewall/rules$($list)$($expansion)"
        }else{
            $url = $url + "/firewall/rules/$($list)$($expansion)"
        }
    }else{
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/config/v1"
        if($hostfirewall){
            $url = $url + "/box/firewall/rules/lists/$($expansion)"
        }else{
            if($serviceName -and $virtualServer){
               $url = $url + "/servers/$($virtualServer)/services/$($serviceName)/firewall/rules/$($list)$($expansion)"
            }else{
            $url = $url + "/forwarding-firewall/rules.$($list)$($expansion)"

            }
          
        }
    }#>



    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }


   
#Sets the token header
    $header = @{"X-API-Token" = "$token"}

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
            $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method GET -Headers $header -Body $data -UseBasicParsing
        }catch [System.Net.WebException] {
                $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                Write-Error $results
                throw   
            }



return ConvertFrom-Json $results.content
}