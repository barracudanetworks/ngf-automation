#Powershell Module

# Introduction
This powershell module provides functionality to create firewall rules for the Barracuda FW. It can be used either directly with a Firewall or with a Control Center managed firewall. 
It functions best with version 8 and above firmware.


#Getting Started
1. Clone or Download the reposityory to your local PC
2. Copy each module folder into one of the POwershell Module directories on your PC. 

  * $env:USERPROFILE\Documents\WindowsPowerShell\Modules
  * C:\Program Files\WindowsPowerShell\Modules
  * C:\Windows\system32\WindowsPowerShell\v1.0\Modules

3. In your powershell session 
```powershell
Import-Module -Name BarracudaCGF
```

```powershell
Import-Module -Name BarracudaCGF
```

#Enabling the API on your Firewall and creating access
https://campus.barracuda.com/product/cloudgenfirewall/doc/79462646/rest-api/

#Examples
There is one example here so far which can transfer the ruleset of the Azure Firewall into a Barracuda Firewall


### REST API
https://campus.barracuda.com/product/cloudgenfirewall/api#