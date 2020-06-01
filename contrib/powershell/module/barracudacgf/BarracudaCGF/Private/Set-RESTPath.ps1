<#
.Synopsis
	Used internally to decide the URL path to use by the commands which may talk to either CC or boxes.
.Description
    This function is used to help decide what path the REST calls should use when making changes to firewall rules, objects etc
.Example
	Is called from the functions with splatting Set-RESTPath @PSBoundParameters
.Notes
v0.1
#>

function Set-RESTPath {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$deviceName,
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string] $devicePort,
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [switch]$notHTTPs,

    #Locations
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
        ValueFromPipelineByPropertyName=$true)]
        [string]$listname,

       <# [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [switch]$hostfirewall,
        #>
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [switch]$ccglobal,

        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [string]$context,

        #used to capture and ignore extra parameters from the calling command
        [Parameter(ValueFromRemainingArguments)]
        $Extra

    )

        
       Write-Debug $context

        #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }

     if($range -or $cluster -or $ccglobal){
        #REST Path for CC
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/cc/v1/config"
        
        if($range -and $cluster -and $serverName -and $serviceName){
        #Forwarding ruleset via CC for v7
            $url = $url + "/ranges/$($range)/clusters/$($cluster)/servers/$($servername)/services/$($serviceName)"
        }elseif($range -and $cluster -and $box -and $serviceName){
        #Forwarding ruleset via CC for v8 
            $url = $url + "/ranges/$($range)/clusters/$($cluster)/boxes/$($box)/service-container/$($serviceName)"
        }elseif($range -and $cluster -and $box){
        #Host ruleset via CC for a box
            $url = $url + "/ranges/$($range)/clusters/$($cluster)/boxes/$($box)"
        #}elseif($range -and $cluster -and $serviceName){
        #
        #    $url = $url + "/ranges/$($range))/clusters/$($cluster)/services/$($serviceName)"
        }elseif($range -and $cluster){
        #Service objects for a cluster in CC
              $url = $url + "/ranges/$($range)/clusters/$($cluster)"
        }elseif($range){
        #Service objects for a Range in CC
            $url = $url + "/ranges/$($range)"
        }
        elseif($ccglobal){
        #assume global
            $url = $url + "/global"
        }

        #Finishes the URL path.
        if($sharedfirewall){
             $url = $url + "/shared-firewall/$($sharedfirewall)/$($context)"
        }elseif($list){
            $url = $url + "/firewall/$($context)/lists/"
        } 
        elseif($listname){
            $url = $url + "/firewall/$($context)/lists/$($listname)"
        }      
        else{
            $url = $url + "/firewall/$($context)"
        }

     
    }else{
    #Direct Firewall paths
        $url = "http$($s)://$($deviceName):$($devicePort)/rest/config/v1"
        if($serviceName -and $serverName){
        #v7 forwarding service objects
            $url = $url + "/servers/$($serverName)/services/$($serviceName)/firewall/$($context)"

        }elseif($serviceName){
        #v8 forwarding objects
            $url = $url + "/service-container/$($serviceName)/firewall/$($context)"
        
        }elseif($fwdingfw){
            $url = $url + "/forwarding-firewall/$($context)"
        }elseif($listname){
            $url = $url + "/service-container/$($serviceName)/firewall/$($context)/lists/$($listname)/"
        }elseif($list){
            $url = $url + "/service-container/$($serviceName)/firewall/$($context)/lists/"
        }
        else{
        #in the absence of any service or server info get the host ruleset
             $url = $url + "/box/firewall/$($context)"
        }
    }
    
return $url
}