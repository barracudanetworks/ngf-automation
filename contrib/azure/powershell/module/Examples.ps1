#
# Examples.ps1
#

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

#Not the best way to store creds but you can test using this.
$password = ConvertTo-SecureString "yourpasswordhere" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential -ArgumentList "root", $password


$a = Get-BarracudaCGFVirtualServers -deviceName $dev_name -devicePort $dev_port -creds $creds 
$a

$b = Get-BarracudaCGFServerServices -deviceName $dev_name -devicePort $dev_port -creds $creds -virtualServerName $a 
$b

$c = Get-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -networkObjectName "Private 10" -virtualServer $a -serviceName $b[2] 
$c


Write-Output $a.Servers

<#Included is an array @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'})
Or a CSV in the format:
type, addresses
ipV4, 10.7.3.0/24
ipV4, 10.7.4.0/24
Or a simple list 

#>

$c = New-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic -name APIOBJECT2 -included @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'},@{'type'='ipV4';'ipV4'='13.67.154.0/24'})  -virtualServer $a -serviceName $b[0] -Debug


$d = New-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -Type generic -name APIOBJECT9 -included @(@{'type'='ipV4';'ipV4'='10.2.2.0/24'})  -virtualServer $a -serviceName $b[2] -Debug -notHTTPs


#CC


$c = Get-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -networkObjectName "Private 10" -range "1" -cluster "NorthCentralUS" -virtualServer "gancusCGF72" -serviceName "gancusCGF72fw" -notHTTPs
$c


$D = New-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -range "1" -cluster "NorthCentralUS" -Type generic -name APIOBJECT3 -included @(@{'type'='ipV4';'ipV4'='13.67.153.16/28'},@{'type'='ipV4';'ipV4'='13.67.154.0/24'})  -virtualServer "gancusCGF72" -serviceName "gancusCGF72fw" -Debug -notHTTPs
$D

$D = Update-BarracudaCGFNetworkObject -deviceName $dev_name -devicePort $dev_port -creds $creds -range "1" -cluster "NorthCentralUS" -type generic -name APIOBJECT3 -included @(@{'type'='ipV4';'ipV4'='10.4.2.0/28'},@{'type'='ipV4';'ipV4'='24.8.2.0/24'})  -virtualServer "gancusCGF72" -serviceName "gancusCGF72fw" -Debug -notHTTPs
$D


