<#
.Synopsis
	Gets all or a single service object
.Description
    This function will create a new service object in either the Host Firewall or Forwarding Firewall or return a powershell object. It expects input of either the -entries or -references to create an object.
    -entries is hashtable that you can use Convert-BarracudaCGFServiceObject-ps1 to create from CSV.

.Example
    ##CC cluster objects - ccglobal objects
    Get-BarracudaCGFServiceObject -deviceName $barracudacc -token $barracudacctoken -ccglobal

    ##CC cluster objects
    Get-BarracudaCGFServiceObject -deviceName $barracudacc -token $barracudacctoken -range 1 

    ##CC cluster objects
    Get-BarracudaCGFServiceObject -deviceName $barracudacc -token $barracudacctoken -range 1 -cluster "EUS2"


    #CC host fw box in cluster
    Get-BarracudaCGFServiceObject -deviceName $barracudacc -token $barracudacctoken -range 1 -cluster "EUS2" -box "GA-EUS2-CGF1"

    #CC forward fw box in cluster with details to get the port numbers etc
    $eus2 = Get-BarracudaCGFServiceObject -deviceName $barracudacc -token $barracudacctoken -range 1 -cluster "EUS2" -box "GA-EUS2-CGF1" -serviceName "NGFW" -details

    #Single FW Host
    Get-BarracudaCGFServiceObject -deviceName $barracudafw -token $fwtoken 

    #Singe FW forwarding object
    Get-BarracudaCGFServiceObject -deviceName $barracudafw -token $fwtoken -fwdingfw

    #Single FW Forwarding v8
    Get-BarracudaCGFServiceObject -deviceName $barracudafw -token $fwtoken -serviceName "NGFW"

    #Singel FW forwarding V7
    Get-BarracudaCGFServiceObject -deviceName $barracudafw -token $fwtoken -serviceName "NGFW" -virtualServer "CSC"
.Notes
v0.1
#>

Function Get-BarracudaCGFServiceObject {
[cmdletbinding()]
param(
#if no device details are provided a powershell object is created.
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$deviceName,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[string] $token,

[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string] $devicePort=8443,

#the below parameters define the ruleset to create the object in
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
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("special", "local")] 
[string]$sharedfirewall,
#triggers 
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$true)]
[string]$objectName,
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$notHTTPs,
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$details,
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$ccglobal,
[Parameter(Mandatory=$false,
ValueFromPipelineByPropertyName=$false)]
[switch]$fwdingfw
)

    <#

#defines the URL to call
    if($range -or $cluster -or $ccglobal){
        #REST Path for CC
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/cc/v1/config"
        
        if($range -and $cluster -and $serverName -and $serviceName){
        #Forwarding ruleset via CC for v7
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/servers/$($PSBoundParameters.("serverName"))/services/$($PSBoundParameters.("serviceName"))"
        }elseif($range -and $cluster -and $box -and $serviceName){
        #Forwarding ruleset via CC for v8 
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/boxes/$($PSBoundParameters.("box"))/service-container/$($PSBoundParameters.("serviceName"))"
        }elseif($range -and $cluster -and $box){
        #Host ruleset via CC for a box
            $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/boxes/$($PSBoundParameters.("box"))"
        #}elseif($range -and $cluster -and $serviceName){
        #
        #    $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))/services/$($PSBoundParameters.("serviceName"))"
        }elseif($range -and $cluster){
        #Service objects for a cluster in CC
              $url = $url + "/ranges/$($PSBoundParameters.("range"))/clusters/$($PSBoundParameters.("cluster"))"
        }elseif($range){
        #Service objects for a Range in CC
            $url = $url + "/ranges/$($PSBoundParameters.("range"))"
        }
        elseif($ccglobal){
        #assume global
            $url = $url + "/global"
        }

        #Finishes the URL path.
        if($sharedfirewall){
             $url = $url + "/shared-firewall/$($PSBoundParameters.("sharedfirewall"))/objects/services"
        }else{
            $url = $url + "/firewall/objects/services"
        }

     
    }else{
    #Direct Firewall paths
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/config/v1"
        if($serviceName -and $serverName){
        #v7 forwarding service objects
            $url = $url + "/servers/$($PSBoundParameters.("serverName"))/services/$($PSBoundParameters.("serviceName"))/firewall/objects/services"

        }elseif($serviceName){
        #v8 forwarding objects
            $url = $url + "/service-container/$($PSBoundParameters.("serviceName"))/firewall/objects/services"
        
        }elseif($fwdingfw){
            $url = $url + "/forwarding-firewall/objects/services"
        }else{
        #in the absence of any service or server info get the host ruleset
             $url = $url + "/box/firewall/objects/services"
        }
    }
    #>

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
    $PSBoundParameters["context"] = "objects/services"

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
    
    
   # if($range -and !$cluster){
   #     Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
   # }

  
    
    if(!$deviceName -and !$token){
        Write-Error "No device or token provided!"

    }else{
        Write-Debug $url
               
            try{
                $results = Invoke-WebRequest -Uri $url -ContentType 'application/json' -Method GET -Headers $header -Body $data -UseBasicParsing
                if((ConvertFrom-Json $results.Content).objects){
		            return (ConvertFrom-Json $results.Content).objects
                }else{
                    return ConvertFrom-Json $results.Content
                }
            }catch [System.Net.WebException] {
                    $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                    Write-Error $results
                    throw   
            }

       
    }

return $results
}