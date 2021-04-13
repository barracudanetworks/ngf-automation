<#
Import_O365IPs.ps1
.Sysnopsis
For use in Azure Automation with standalone CGF's to import the O365 network ranges.
.Description 
It is recommended you use this with powershell v7

#>

Import-Module BarracudaCGF
#Setup the device details - could also be a variable in Azure automation
#Recommend using a FQDN to the Azure LB name and installing a certificate on the CGF for that name. 
$dev_name = "gaeuscc.eastus2.cloudapp.azure.com"
$virtualServer =  "ncustest"
$serviceName = "gancusngf72fw"
$range = "1"
$cluster = "NorthCentralUS8"

#Get Credentials - create an Azure Automation credential for your CGF and apply it's name here
#$token = Get-AutomationPSCredential -Name 'CGFtoken'
$creds = Get-Credential
#If running outside of Azure automation and using token
#$token = Read-Host -Prompt "Please provide API Token" -AsSecureString 



#No longer required by Powershell 6.1 and above.
#This function by default enabled TLS1.2, however it can be modified with -allowSelfSigned to allow self-signed certificates or -noCRL to disable CRL checks
#Set-BarracudaCGFtoIgnoreSelfSignedCerts -allowSelfSigned -noCRL

$url = "https://endpoints.office.com/endpoints/worldwide?ClientRequestId=b10c5ed1-bad1-445f-b386-b919946339a7"


#Get's the content of the json page.
try{
	$content = ConvertFrom-Json -InputObject (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
}catch{
	Write-Error "Unable to collect IP ranges from URL $($url)"
}

ForEach($item in $content){
Write-Output "$($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)"
    If($item.ips){
        <#
        #IPv4
        $ipv4 = $item.ips.Where({$_ -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"})
		#IPv6
        $ipv6 = $item.ips.Where({$_ -notmatch "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"})

		
			$included = $(if($ipv4){New-BarracudaNetObject -objectType "ipV4" -objectList $ipv4}) + $(if($ipv6){New-BarracudaNetObject -objectType "ipV6" -objectList $ipv6})
            Write-Output "Adding network object $($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)"
			$results = New-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic -name "$($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)" `
                     -included $included -virtualServer $virtualServer -serviceName $serviceName -range $range -cluster $cluster

            Get-BarracudaCGF-ResultMessage $results;
			#Changes request to a replacement update if object already exists
            if($results -eq 409){
                      $results = Update-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic `
                     -name "$($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)" -included $included `
                     -virtualServer $virtualServer -serviceName $serviceName -replace -range $range -cluster $cluster 
                     Get-BarracudaCGF-ResultMessage $results

            }
        
      #>
    }

    Write-Host "URLS"
    if($item.urls){
    #Write-Output "Not able to add URL's yet via the API. Not Supported."
	#if($FirewallVersion -lt 8)
    #    Write-Warning "Prior to 8.0.2 DNS rules are not supported"   
	#}else{
		ForEach($u in $item.urls){
            #Excludes wildcard domains as these cannot be used in Barracuda Network rules, however the Application > Microsoft Office would likely already cover these items. 
			if($u -notmatch '\*'){

                $u
            }
            #New-BarracudaCGFNetworkObject -objectType "hostname" -o
        $results = New-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type hostname  `
                     -included $included -virtualServer $virtualServer -serviceName $serviceName -range $range -cluster $cluster

            Get-BarracudaCGF-ResultMessage $results;
			#Changes request to a replacement update if object already exists
            if($results -eq 409){
                      $results = Update-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic `
                     -name "$($item.serviceArea)_$($item.serviceAreaDisplayName)_$($item.id)" -included $included `
                     -virtualServer $virtualServer -serviceName $serviceName -replace -range $range -cluster $cluster 
                     Get-BarracudaCGF-ResultMessage $results

            }
		}

        pause

        #>
    }

   # Write-Host "Ports"
   # $item.tcpPorts
}


Write-Output "Script complete."

 