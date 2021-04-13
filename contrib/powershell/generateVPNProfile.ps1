#This file is for use with automated deployment technologies such as Microsoft Intune to deploy a VPN policy.

#Rather than directly editing this, I personally tend to create a test client and then take the settings from it's registry keys and update here. 

#Deploys the policy to the default user key so that all users can access it
$regpath = "HKU:\.DEFAULT\Software\Phion\phionvpn\Profile"
New-PSDrive HKU Registry HKEY_USERS

Push-Location

Set-Location $regpath
Test-Path .\1
New-Item -Path .\ -Name 1
#Set to 1 to enable the policy
New-ItemProperty -Path "$regpath\1" -Name "Enabled" -Value "1"  -PropertyType "DWORD"

#Name for the Profile
New-ItemProperty -Path "$regpath\1" -Name "Description" -Value "TESTVPN"  -PropertyType "string"
#IP or FQDN of VPN server, can be a comma seperated list
New-ItemProperty -Path "$regpath\1" -Name "server" -Value "23.96.233.112"  -PropertyType "string"

#Select Authentication Type
#0 = Personal Licenses 
#1 = X509
#2 = Username and Password
#2 = Username and Password & X509
#3 = SAML (for use with CGW and CGF 8.2 only!)
New-ItemProperty -Path "$regpath\1" -Name "AuthType" -Value "2"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "AuthUser" -Value "1"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "license" -Value ""  -PropertyType "string"

New-ItemProperty -Path "$regpath\1" -Name "proxyType" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "proxy" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "proxyuser" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "proxydomain" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "simulateSSL" -Value "0"  -PropertyType "DWORD"
#Configure these to define the encyrption levels  2=SHA1, 5=SHA256, 6=SHA512
New-ItemProperty -Path "$regpath\1" -Name "hash" -Value "5"  -PropertyType "DWORD"
#Set's the Encryption for the tunnel  5=AES128 40=SHA256
New-ItemProperty -Path "$regpath\1" -Name "encryption" -Value "4"  -PropertyType "DWORD"
# Sets the tunnel mode, 1=TCP 2 = UDP 3 = Optimised (Hybrid)
New-ItemProperty -Path "$regpath\1" -Name "mode" -Value "2"  -PropertyType "DWORD"
#Default value is On/1 to enable Compression of traffic
New-ItemProperty -Path "$regpath\1" -Name "streamCompression" -Value "1"  -PropertyType "DWORD"
#Default value for how often to keep tunnel alive
New-ItemProperty -Path "$regpath\1" -Name "timeoutAlive" -Value "10"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "silent" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "tunnelSoftHeartbeat" -Value "1"  -PropertyType "DWORD"
#Enable Exclusive Network Access to tunnel all traffic up VPN
New-ItemProperty -Path "$regpath\1" -Name "allowENA" -Value "1"  -PropertyType "DWORD"
#Enable this to enable the Firewall Ruleset in the client - in particular offline ruleset
New-ItemProperty -Path "$regpath\1" -Name "allowFWRule" -Value "1"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "tunnelProbing" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "tunnelRTT" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "reconnectCycle" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "TimeoutConnect" -Value "30"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "TryTimeout" -Value "60"  -PropertyType "DWORD"
#Enable OTP support
New-ItemProperty -Path "$regpath\1" -Name "oneTimePassword" -Value "0"  -PropertyType "DWORD"
#Set to 1 for the user not to be prompted to trust the VPN Server certificate
New-ItemProperty -Path "$regpath\1" -Name "autoTrustX509Server" -Value "1"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "enforceServerCertValidation" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "fastDynReconnect" -Value "1"  -PropertyType "DWORD"
#Set to 1 to immediately try to reconnect
New-ItemProperty -Path "$regpath\1" -Name "ReconnectImmediate" -Value "1"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "reconnectAdapterReset" -Value "1"  -PropertyType "DWORD"
#Mark this VPN profile as the fallback to use if all other VPN profiles fail
New-ItemProperty -Path "$regpath\1" -Name "FallbackProfile" -Value "0"  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "TerminateCountdown" -Value "00000002"  -PropertyType "DWORD"

New-ItemProperty -Path "$regpath\1" -Name "usePolSrv" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "usePolSrvInterceptVPNHandshake" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "usePolSrvTerminateVPN" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "usePolSrvTimeout" -Value "30"  -PropertyType "DWORD"
#
New-ItemProperty -Path "$regpath\1" -Name "ADAccessibility" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "ADAlwaysDetect" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "lastActiveDirectory" -Value "1"  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "ADProbingTimeout" -Value "00000003"  -PropertyType "DWORD"
#Set to 1 to remember credentials
New-ItemProperty -Path "$regpath\1" -Name "rememberLoginUser" -Value "1"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "credential_Persist" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "unattended" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "ipLegacyMode" -Value "1"  -PropertyType "DWORD"
#Enter here scripts to be triggered when the VPN starts or Stops
New-ItemProperty -Path "$regpath\1" -Name "startScript" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "stopScript" -Value ""  -PropertyType "string"
#Set to 1 to run the Start and Stop scripts as users rather than computer
New-ItemProperty -Path "$regpath\1" -Name "startScriptAsServiceUser" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "stopScriptAsServiceUser" -Value "0"  -PropertyType "DWORD"

#Set to 1 to terminate VPN when user logs off
New-ItemProperty -Path "$regpath\1" -Name "terminateIfUserLogout" -Value "1"  -PropertyType "DWORD"
#Set to 1 to enable VPN selection at Login Screen
New-ItemProperty -Path "$regpath\1" -Name "enableMSLogon" -Value "1"  -PropertyType "DWORD"
#Configure these to customised the names for the Username, Password and OTP fields
New-ItemProperty -Path "$regpath\1" -Name "userNameInputLabel" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "userPasswordInputLabel" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "otpInputLabel" -Value ""  -PropertyType "string"

#Compete these for Certificate Authentication
New-ItemProperty -Path "$regpath\1" -Name "certissuer" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certissuerX500" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "CertMultipleSelection" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "certname" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "CertSearchOrder" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "CertLookupPattern" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certserialnumber" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certConditionSubject" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certConditionIssuer" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certConditionSerial" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certConditionThumbprint" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certConditionTemplateOID" -Value ""  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "certMatchPolicy" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "KeySpec" -Value "0"  -PropertyType "DWORD"
New-ItemProperty -Path "$regpath\1" -Name "store" -Value "MY"  -PropertyType "string"
New-ItemProperty -Path "$regpath\1" -Name "StoreFlags" -Value "65536"  -PropertyType "DWORD"

New-ItemProperty -Path "$regpath\1" -Name "MultiTargetBalancing" -Value "0"  -PropertyType "DWORD"

# For CloudGen WAN Deployments leave uncommented
#New-ItemProperty -Path "$regpath\1" -Name "CGWGatewayName" -Value ""  -PropertyType "string"
#New-ItemProperty -Path "$regpath\1" -Name "CGWGatewayUUid" -Value ""  -PropertyType "string"
#New-ItemProperty -Path "$regpath\1" -Name "CGWLastModifiedDateTime" -Value ""  -PropertyType "string"
#New-ItemProperty -Path "$regpath\1" -Name "CGWRegionId" -Value ""  -PropertyType "string"
#New-ItemProperty -Path "$regpath\1" -Name "CGWRegionName" -Value ""  -PropertyType "string"
#New-ItemProperty -Path "$regpath\1" -Name "CGWVirtualWANName" -Value ""  -PropertyType "string"
#New-ItemProperty -Path "$regpath\1" -Name "CGWVirtualWANUUid" -Value ""  -PropertyType "string"

#Return to old path
Pop-Location
Push-Location

#This section sets client wide registry changes , it is not complete
Set-Location "HKU:\.DEFAULT\Software\Phion\phionvpn\settings" 

#Enable the below to setup Pre logon VPN auth
#Set-ItemProperty -Path "HKU:\.DEFAULT\Software\Phion\phionvpn\settings" -Name "UsePrelogon" -Value "1"
#Enable the below to setup the credential provide to collect credentials for SSO
#Set-ItemProperty -Path "HKU:\.DEFAULT\Software\Phion\phionvpn\settings" -Name "CPSSOVPNConnectDefault" -Value "1"

Pop-Location

write-output "Script reached end"