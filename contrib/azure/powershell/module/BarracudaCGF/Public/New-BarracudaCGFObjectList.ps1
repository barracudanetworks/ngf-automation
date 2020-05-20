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
	type, addresses
	ipV4, 10.7.3.0/24
	ipV4, 10.7.4.0/24
	Or a simple list seperated by , or a powershell Array''
.Example
	New-BarracudaNGFObject -objectType ipV4 -objectValue 10.2.1.3
	New-BarracudaNGFObject -objectType ipV4 -csvFileName C:\myfile.csv


.Notes
	Handles IPv4 and IPv6
	added -v7 which should be enabled if the subnet masks do not appear correctly in the FW. Older API releases did not convert to a reverse mask. 
	v7.2 - v8.0 do not need this and should use -v8
    added -v8 to handle the earlier formatting, v8.0.1 onwards which is the default doesn't use the objectType parameter at all and needs no extra
#>
Function New-BarracudaCGFObjectList{
 [cmdletbinding()]

param(
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("ipV4", "rangeV4", "networkV4", "ipV6", "reference")]  
[string]$objectType,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$objectValue,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
$csvFileName,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
$objectList,
[switch]$reference,
[switch]$v7,
[switch]$v8
)


    $array=@()
	if($v7){
		switch($objectType){
			"ipV4" {
				if($csvFile){
					ForEach($item in (ConvertFrom-CSV (Get-Content $csvFileName))){
						$array = $array += @{type="$($item.type)";$item.type="$($item.address.Split('/')[0])/$(32-$item.address.Split('/')[1])"}
					}
				}elseif($objectList){
					ForEach($item in $objectList){
						$array = $array += @{type=$objectType;$objectType="$($item.Split('/')[0])/$(32-$item.Split('/')[1])"}
					}
				}else{
						$hashtable = @{type="$objectType";$objectType="$($objectValue.Split('/')[0])/$(32-$objectValue.Split('/')[1])"}
				}
			}
			"ipv6" {
				if($csvFile){
					ForEach($item in (ConvertFrom-CSV (Get-Content $csvFileName))){
						$array = $array += @{type="$($item.type)";$item.type="$($item.address)"}
					}
				}elseif($objectList){
					ForEach($item in $objectList){
						$array = $array += @{type=$objectType;$objectType="$($item)"}
					}
				}else{
						$hashtable = @{type="$objectType";$objectType="$($objectValue)"}
				}
			}
			default{}
		}
	}elseif($v8){
		switch($objectType){
			"ipV4" {
				ForEach($i in $objectList){
						$array = $array += @{type="ipV4";ipV4="$($i)"}
				}
			}
			"ipV6" {
				ForEach($i in $objectList){
						$array = $array += @{type="ipV6";ipV6="$($i)"}
				}
                
			}
		}
	}else{
        if($reference){
            
            ForEach($i in $objectList){
		        $array = $array += @{"references"="$($i)"}
		    }
        }else{
            ForEach($i in $objectList){
		        $array = $array += @{"entry"=@{ip="$($i)"}}
		    }
        }
    }

return $array
}
