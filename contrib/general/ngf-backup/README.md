# Backup Scripts for Barracuda NextGen Firewall F-Series and NextGen Control Center

## Introduction
The scripts in this project will backup the configuration of the Barracuda NextGen Firewall F-Series or the Barracuda NextGen Control Center to either an FTP server or an Azure Blob Storage Container.

## Installation
<ol>
    <li>Copy the script to the firewall.</li>
    <li>Verify and make sure the script is executable: <code># chmod 755 ngfbackup-as.sh</code></li>
    <li>Adapt the variables as needed in the script and copy the script on the NGF or NGCC.</li>
    <li>Run the script to verify everything is working fine.</li>
    <li>Schedule the script to run every day or week using the cronjob functionality in the system. More info can be found <a href="https://campus.barracuda.com/product/nextgenfirewallf/article/NGF71/ConfigCronjobs/">here</a></li>
</ol>

## Retrieve the Shared Access Signature

The Shared Access Signature token is generated based on the access keys in the Azure Storage container. It is valid for a specific timeframe. When the access key is deleted it is also becomes invalid. It is best to configure start date an time of the Shared Access Signature well before you do you tests. (1 day extra for example).

To retrieve Shared Access Signature you need access to the Azure Portal.

<ol>
    <li>Login into the Azure Portal</li>
    <li>Create or access the Azure Storage Account you want to use for your the backup</li>
    <li>Create a new container that will be hold the backup</li>
    <li>Go to the 'Shared Access Signature' option and create the token. The minimal requirements are Access to Blob, Allow Object resource type and the persmission to Add and Create.<img src="../../../../../raw/master/contrib/general/ngf-backup/images/sharedaccesssignature.png"/></li>
    <li>Copy the SAS token start with '?sv=' in the variable in the backup script.</li>
</ol>
