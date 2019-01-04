#Sample Powershell Module for CloudGen Firewall

This sample powershell module can be used locally or via Azure automation to perform changes via the Cloud Gen Firewalls API. It has been tested with versions 7.2.2 and above.

This module does not contain all functions of the API at this time. Contributions are welcome.

For best security use SSL to communicate with the FW

When using SSL the easiest method to avoid certificate issues is to put a FQDN on the Azure Public IP used and use this in the certificate as the SubjectName, please note on Windows you will probably need to install this Self-Signed certificate into the Trusted Root Certificate Authorities location.