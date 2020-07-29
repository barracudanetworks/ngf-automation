<#
.Synopsis
	Takes input in the form of a CSV, list or single IP and converts into an array suitable for use with New-BarracudaNGFNetworkObject command
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
	Or a simple list seperated by , or a powershell Array ''
.Example
	New-BarracudaNGFObject -objectType ipV4 -objectValue 10.2.1.3
	New-BarracudaNGFObject -objectType ipV4 -csvFileName C:\myfile.csv
    Convert

.Notes
	Handles IPv4 and IPv6
	added -old which should be enabled if the subnet masks do not appear correctly in the FW. Older API releases did not convert to a reverse mask. v7.2 and up do not need this. 
#>
Function Convert-BarracudaCGFNetworkObject{
    [cmdletbinding()]
param(
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[ValidateSet("ipV4", "rangeV4", "networkV4", "ipV6", "reference","mac")]  
[string]$objectType,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$objectValue,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
$csvFileName,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[array]$objectList,
[Parameter(Mandatory=$false,ValueFromPipeline=$false)]
[string]$comment,
[switch]$old
)


    $array=@()
	if($old){
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
	}else{
		switch($objectType){
			"ipV4" {
				if(!$objectList){
                    $array = @{entry=@{ip="$($objectvalue)";comment="$($comment)"}}
                }else{
                    ForEach($i in $objectList){
						    #$array = $array += @{entry=@{type="ipV4";ip="$($i)";comment="$($comment)"}}
                            $array = $array += @{entry=@{ip="$($i)";comment="$($comment)"}}
				    }
                }
			}
			"ipV6" {
				ForEach($i in $objectList){
						#$array = $array += @{entry=@{type="ipV6";ip="$($i)";comment="$($comment)"}}
                        $array = $array += @{entry=@{ip="$($i)";comment="$($comment)"}}
				}
			}
			"mac" {
				ForEach($i in $objectList){
						#$array = $array += @{entry=@{type="mac";mac="$($i)";comment="$($comment)"}}
                $array = $array += @{entry=@{mac="$($i)";comment="$($comment)"}}
				}
			}
		}
	}

return $array
}





