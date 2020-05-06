<#
.Synopsis
	Takes input in the form of a CSV, list or single IP and converts into an array suitable for use with New-BarracudaNGFNetworkObject
.Description
    This function can be used to create a suitable array to be used with the New-BarracudaNGFNetworkObject command as either the included or excluded IP's 
	for the network object creation. 
	At this time all objects inputted should be of the same type. 
	The input is expected to be in normal notation e.d 10.2.3.0/24 and will be converted by the function to phion notation 10.2.3.0/8 
	This will create an array like; @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'})
	From a CSV in the format;

	protocol;from-to;ports;dynamicservice;servicelabel;comment;ProtectionProtocols;protectionAction;protectionPolicy;references
    tcp;1024-65535;4443;NONE;CustomWebLabel;mycomment;HTTP;report;whitelist
    udp;10-50;53;NONE;CustomDNSLabel;



	Or a simple list seperated by , or a powershell Array''
.Example
	New-BarracudaNGFObject -objectType ipV4 -objectValue 10.2.1.3
	New-BarracudaNGFObject -objectType ipV4 -csvFileName C:\myfile.csv


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
[array]$clientPortUsed=@("1024","65535"),
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[array]$ports,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$dynamicService="NONE",
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$serviceLabel,

#protocol protection settings
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$protectionprotocols,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("none", "report", "reset", "drop")] 
[string]$action,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("whitelist", "blacklist")] 
[string]$policy,

[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$comment,
[switch]$old
)

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
    #to add handling later to create single protocol arrays.
		switch($protocol){
			default {
           	    $array =  @{entry=`
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
                $array.Add("plugin",$item.Plugin)
            }

            if($item.protectionAction){
                
                $array['entry'].Add("protocolProtection",[hashtable]@{protocols=$item.ProtectionProtocols.Split(";");action="$($item.protectionAction)";policy="$($item.protectionpolicy)"})
            }
           	   
			}
			"icmp" {
    			$array = $array += @{entry=@{type="icmp";maxsize="$($icmpmaxSize)";minDelay="$($icmpminDelay)"}}
			}
        }
    }

return $array
}

