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