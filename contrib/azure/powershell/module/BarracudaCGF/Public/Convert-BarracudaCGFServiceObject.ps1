<#
.Synopsis
	Takes input in the form of a CSV, or a suitable collection of parameter values and converts into a hashtable of multiple or single objects.
.Description
    This function can be used to create a suitable hashtable to be used with the New-BarracudaCGFServiceObject command for the service object creation

	 
	The input is expected to be in normal notation e.d 10.2.3.0/24 and will be converted by the function to phion notation 10.2.3.0/8 
	This will create an hashtable 
	From a CSV in the format;

	protocol;from-to;ports;dynamicservice;servicelabel;comment;ProtectionProtocols;protectionAction;protectionPolicy;references
    tcp;1024-65535;4443;NONE;CustomWebLabel;mycomment;HTTP;report;whitelist
    udp;10-50;53;NONE;CustomDNSLabel;



	Or a simple list seperated by , or a powershell Array''
.Example
	#Basic TCP OBJECT
    $objectout = Convert-BarracudaCGFServiceObject -protocol "tcp" -ports "12345" -Comment "this is my service object entry 1"
    #Basic UDP object
    $objectout2 = Convert-BarracudaCGFServiceObject -protocol "udp" -ports "54321" -Comment "this is my service object entry 2"
    #Basic ICMP object
    $objectout3 = Convert-BarracudaCGFServiceObject -protocol "icmp"  -Comment "this is my icmp service object entry 3"
    #port range TCP object
    $objectout4 = Convert-BarracudaCGFServiceObject -protocol "tcp" -ports "1023-1025","80","95" -Comment "this is my port range object entry 4"
    #Plugin Enabled object - eg. FTP
    $objectout5 = Convert-BarracudaCGFServiceObject -protocol "tcp" -ports "6000-7000" -dynamicService  -Comment "this is my icmp service object entry 3"


.Notes
	Can be used to convert CSV to hashtable, a single object values to a hashtable or a hashtable of objects of the same protocol with differing port values.
#>
Function Convert-BarracudaCGFServiceObject{
    [cmdletbinding()]
param(
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("tcp", "udp", "icmp")]  
[string]$protocol,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
$csvFileName,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[hashtable]$clientPortUsed=@{"from"=1024; "to"=65535},
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[array]$ports,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$dynamicService="NONE",
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$serviceLabel,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[int]$sessionTimeout=86400,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[int]$balancedTimeout=20,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[int]$icmpmaxSize=10000,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[int]$icmpminDelay=10,
#protocol protection settings
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$protectionprotocols,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("none", "report", "reset", "drop")] 
[string]$action,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("whitelist", "blacklist")] 
[string]$policy="whitelist",

[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$comment,
[switch]$old
)

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
    }

    $array=@()

    if($csvFile){
        ForEach($item in (ConvertFrom-CSV (Get-Content $csvFileName))){
            $values =  @{entry=`
                @{"$($item.protocol)"=`
                    @{clientPortUsed=@{from=[int]$($item.from);to=[int]$($item.to)};`
                    ports=$item.ports.split(";");`
                    dynamicService="$($item.dynamicservice)";`
                    serviceLabel="$($item.serviceLabel)"`
                    };`
                    sessionTimeout=[int]$($item.SessionTimeout);`
                    balancedTimeout=[int]$($item.BalancedTimeout);`
                    comment=$($item.comment);`
                    protocol=$($item.protocol)}}

            if($item.plugin){
                $values.Add("plugin",$item.Plugin)
            }

            if($item.protectionAction){
                
                $values['entry'].Add("protocolProtection",[hashtable]@{protocols=$item.ProtectionProtocols.Split(";");action="$($item.protectionAction)";policy="$($item.protectionpolicy)"})
            }

            $array = $array += $values
        }
    }else{
    #handles single inputs in the parameters

    #to add handling later to create single protocol arrays.
		switch($protocol){
			default {
           	    $array =  @{entry=`
                @{"$($protocol)"=`
                    @{clientPortUsed=$clientPortUsed;`
                    ports=$ports;`
                    dynamicService="$dynamicservice";`
                    serviceLabel=$serviceLabel`
                    };`
                    sessionTimeout=[int]$($SessionTimeout);`
                    balancedTimeout=[int]$($BalancedTimeout);`
                    comment=$($comment);`
                    protocol=$($protocol)}}

            if($plugin){
                $array.Add("plugin",$Plugin)
            }

            if($protectionAction){
                
                $array['entry'].Add("protocolProtection",[hashtable]@{protocols=$ProtectionProtocols.Split(";");action="$($protectionAction)";policy="$($protectionpolicy)"})
            }
           	   
			}
			"icmp" {
                #changes default values for ICMP
                if($sessionTimeout=86400){$sessionTimeout=120}    

    			$array = $array += @{entry=`
                                    @{protocol="ICMP";`
                                    "icmp"=@{`
                                      maxsize=$icmpmaxSize;`
                                      minDelay=$icmpminDelay;`

                                      };`
                                      sessionTimeout=[int]$($SessionTimeout);`
                                      balancedTimeout=[int]$($BalancedTimeout)`
                                      }`
                                      }
			}
        }
    }

return $array
}

