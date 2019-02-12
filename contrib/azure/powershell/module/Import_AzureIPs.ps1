<#
Import_AzureIPs.ps1
.Sysnopsis
For use in Azure Automation with standalone NGF's
.Description 

#>
Import-Module Barracuda_CGF_Module
#Setup the device details - could also be a variable in Azure automation
#Recommend using a FQDN to the Azure LB name and installing a certificate on the CGF for that name. 
$dev_name = ""
$dev_port = "8443"
#Define the Virtual Server name and Firewall Service Name
$virtualServer = "S1"
$serviceName = "NGFW"
#If using Control Center for management uncomment the below and also the comments starting #CC as these provide the below values to the function
#$range = "1"
#$cluster = "NorthCentralUS"

#Get Credentials - create an Azure Automation credential for your NGF and apply it's name here
$creds = Get-AutomationPSCredential -Name '<your_automation_credential>'

#This is the URL for the Microsoft Azure IP Ranges

$url = "https://www.microsoft.com/en-gb/download/confirmation.aspx?id=41653"

#Finds the link in the page to the XML file
try{
    $xmlhref = ((Invoke-WebRequest -Uri $url -UseBasicParsing).Links | Where-Object -Property href -Like -Value "*PublicIP*xml").href
    if($xmlhref.Count -gt 1){
        [string]$xmlhref = $xmlhref[0]
    }
}catch{
    Write-Error "Unable to get link to IP list from $url"
}
#Get's the content of the XML page.
try{
    $content = (Invoke-WebRequest -Uri $xmlhref -UseBasicParsing).RawContent
}catch{
    Write-Error "Unable to get list of IP's from $xmlhref"
}
#Strings out the headers from the RawContent and just gathers the xml
[xml]$xml = $content.Substring($content.IndexOf("<?xml"))

#Iterates through the objects
ForEach($region in $xml.AzurePublicIpAddresses.Region){

#Converts the XML objects into a JSON array for the API to insert.
    [array]$included = @()

    ForEach($ip in $region.IpRange.Subnet){
        $included += @{'type'='ipV4';'ipV4'="$($ip.Split('/')[0])/$(32-$ip.Split('/')[1])"}
    }

#starts updating FW
    Write-Output "Starting to add Region: $($region.Name)"

    $results = New-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic -name "Azure Region $($region.Name)" -included $included -virtualServer $virtualServer -serviceName $serviceName #CC -range $range  -cluster $cluster 

	Get-BarracudaCGF-ResultMessage $results;
			#Changes request to a replacement update if object already exists
            if($results -eq 409){
                      $results = Update-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic `
                     -name "Azure Region $($region.Name)" -included $included `
                     -virtualServer $virtualServer -serviceName $serviceName  -replace #CC -range $range  -cluster $cluster 
                     Get-BarracudaCGF-ResultMessage $results

            }

    
}

Write-Output "Script complete."
 