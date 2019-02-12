# Azure User Defined Routing Automation Script

## Introduction

To direct traffic destined for ExpressRoute towards the Barracuda Next Gen Firewall F we need to create user defined routes. Routing in Azure works on a longest prefix match first. When there is are multiple results the routing will be decided based on the following order:
<ol>
<li>User defined routes</li>
<li>BGP Routes (ExpressRoute)</li>
<li>System routes</li>
</ol>

More information can be found on <a href="https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview">this link</a><br/>

## Step-by-Step Instructions

This Azure automation script will read the routes injected via BGP from the ExpressRoute provider and create User Defined Routes. It is required to setup an Azure Automation account. To setup the Azure Automation Account and the script you need to follow these steps:

The number of routes per User Defined Route table is by default 100. If you need more entries this is possible by contacting Microsoft support. Limitations are listed on <a href="https://docs.microsoft.com/en-us/azure/azure-subscription-service-limits">this link</a>.

<ol>
    <li>Login into the Azure Portal</li>
    <li>Go to the Azure Marketplace and search for Azure Automation <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation1.png"/></li>
    <li>Create the Azure Automation account and automatically create the "Azure Run As account" <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation2.png"/></li>
    <li>Upgrade and/or install any addtional modules as indicated in the script <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation3.png"/></li>
    <li>Create a Runbook and import the powershell script <img src="../../../../../../raw/master/contrib/azure/powershell/udrsync/cudaautomation4.png"/></li>
</ol>

##### DISCLAIMER: ALL OF THE SOURCE CODE ON THIS REPOSITORY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL BARRACUDA BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOURCE CODE. #####