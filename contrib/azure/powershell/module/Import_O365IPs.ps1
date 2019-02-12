<#
Import_O365IPs.ps1
.Sysnopsis
For use in Azure Automation with standalone CGF's to import the O365 network ranges.
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

#Get Credentials - create an Azure Automation credential for your CGF and apply it's name here
$creds = Get-AutomationPSCredential -Name '<your_automation_credential>'

#This function by default enabled TLS1.2, however it can be modified with -allowSelfSigned to allow self-signed certificates or -noCRL to disable CRL checks
Config-TLSSettings

#Not XML anymore. :(
$url = "https://endpoints.office.com/endpoints/worldwide?ClientRequestId=b10c5ed1-bad1-445f-b386-b919946339a7"


#Get's the content of the XML page.
try{
	$content = ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
}catch{
	Write-Error "Unable to collect IP ranges from URL $($url)"
}

#If using a self-signed certificate on a machine where you can't install it into trusted roots (Like Azure Automation) then use the below
Config-TLSSettings -allowSelfSigned

ForEach($item in $content){
Write-Output "$($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)"
    If($item.ips){
        #IPv4
        $ipv4 = $item.ips.Where({$_ -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"})
		#IPv6
        $ipv6 = $item.ips.Where({$_ -notmatch "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"})

		
			$included = $(if($ipv4){New-BarracudaNetObject -objectType "ipV4" -objectList $ipv4}) + $(if($ipv6){New-BarracudaNetObject -objectType "ipV6" -objectList $ipv6})
            Write-Output "Adding network object $($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)"
			$results = New-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic -name "$($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)" `
                     -included $included -virtualServer $virtualServer -serviceName $serviceName #CC -range $range -cluster $cluster

            Get-BarracudaCGF-ResultMessage $results;
			#Changes request to a replacement update if object already exists
            if($results -eq 409){
                      $results = Update-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic `
                     -name "$($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)" -included $included `
                     -virtualServer $virtualServer -serviceName $serviceName -replace #CC -range $range  -cluster $cluster 
                     Get-BarracudaCGF-ResultMessage $results

            }
        

    }

    Write-Host "URLS"
    if($item.urls){
    Write-Output "Not able to add URL's yet via the API. Not Supported."
        <#	if($FirewallVersion -lt 8)
        
	}else{
		ForEach($u in $item.urls){
			$u
			New-BarracudaCGFNetworkObject -
		}

        

        #>
    }

   # Write-Host "Ports"
   # $item.tcpPorts
}



Write-Output "Script complete."

 