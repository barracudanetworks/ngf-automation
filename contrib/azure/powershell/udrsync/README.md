# Azure User Defined Routing Automation Script

To direct traffic destined for ExpressRoute towards the Barracuda Next Gen Firewall F we need to create user defined routes. Routing in Azure works on a longest prefix match first. When there is are multiple results the routing will be decided based on the following order:
<ol>
<li>User defined routes</li>
<li>BGP Routes (ExpressRoute)</li>
<li>System routes</li>
</ol>

More information can be found on <a href="https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview">this link</a><br/>

This Azure automation script will read the routes injected via BGP from the ExpressRoute provider and create User Defined Routes. It is required to setup an Azure Automation account. To setup the Azure Automation Account and the script you need to follow these steps:

<ol>
    <li>Login into the Azure Portal</li>
    <li>Go to the Azure Marketplace and search for Azure Automation <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation1.png"/></li>
    <li>Create the Azure Automation account and automatically create the "Azure Run As account" <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation2.jpg"/></li>
    <li>Upgrade and/or install any addtional modules as indicated in the script <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation3.jpg"/></li>
    <li>Create a Runbook and import the powershell script <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation4.jpg"/></li>
</ol>
