#This may be needed for Version 5 and below powershell which is not recommended to be used. The module would need modifying to work with that version as it is now written for 7.x powershell.  
#This needs to be ran at the start to set the environment to support Tls1.2 and to allow self signed certificates.
#Further for each command in Public folder the -SkipCertificateCheck would need removing from the end of Invoke-WebRequest command. 


Function Set-BarracudaCGFtoIgnoreSelfSignedCerts{
[cmdletbinding()]
param(
[switch]$allowSelfSigned,
[switch]$noCRL
)



#Enables TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::TLS12, [Net.SecurityProtocolType]::Tls11
	if($allowSelfSigned){
	if (-not("dummy" -as [type])) {
    add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class Dummy {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }

    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(Dummy.ReturnTrue);
    }
}
"@
}

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [dummy]::GetDelegate()



	#	[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
	}
	if($noCRL){
	#May be required to ignore CRLs
		[Net.ServicePointManager]::CheckCertificateRevocationList = { $false }
	}
}