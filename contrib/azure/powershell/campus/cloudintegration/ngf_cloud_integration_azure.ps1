#
# ngf_cloud_integration_azure.ps1
#
# This script uploads a certificate to Azure
# and creates an Azure Rm Role For use with the UDR updating via the load balancers.
# Written by Jeremy MacDonald and modified Michael Zoller
#-----Variables
$ADAppName = 'NGF';  #String used to hold App Name for Azure Back End, Can always be NGF;
$pathToCERfile;      #String used to hold file path;
$resourceGroupName;  #String used to hold Reource Group that the firewalls are contained in;
$subcriptionID;      #Sting used to hold Subcription ID of Azure Account.
$identifier;         #String containing Azure RM AD identifier.
$rolename;           #String containing Azure RM AD Role name;
$role;               #Custom role object for NGF Cloud Intergration.
$firewallRole;       #Role object for NGF.
$endDate;            #Ending date for the uploaded certificate.
$prince;             #Certificate to be uploaded to Azure for role verification.
$cred;               #Holds login infomation in a secure variable.
$loginResult         #Stores the Login result informaion (USER ID, ACCOUND ID ect).
$exitData            #Stores all data needed to be saved after completion. of program.
#-----End Variables

#-----Functions

#----- Greets people upon load.
function Greeting
{
clear;
Write-Host "*****************************************************************************"
Write-Host " Cloud Integration for NextGen Firewall in Azure"
Write-Host "*****************************************************************************"
Write-Host " "
}
#-----Gets and checks for the existance of the Certificate File (Arm.cer)
function CheckCERFile
{
	$exist = 0; 	#Variable to check if file exists, set to does not exist.
	while (!$exist)
{
	Write-Host "Enter the complete path to the certificate includng file name";
	$pathToCERfile = Read-Host("Typically C:\pathToCERfile\arm.cer") #Prompts user to enter patch and name of cert file.
	$exist = [System.IO.File]::Exists($pathToCERfile);
	if (! $exist) #Check if certificate exists and loop on error.
		{
		 Write-Host "File not found @ $pathToCERfile, verify the path." -ForegroundColor Yellow;
		}
	else
		{
		 Write-Host "Using certificate file found at @ $pathToCERfile" -ForegroundColor Green;
		}
}

	return $pathToCERfile;
}
#----- Gets Reource Group from user and verifies its existance.
function GetResourceGroup
{
#-----Can display all know Resource Groups if requested.
    $exists = $FALSE;
	$groupname = Read-Host("Enter Resource group name for the VNET");
	Get-AzureRmResourceGroup -Name $groupname -ev exists -ea 0;
	while ($exists)
	{
    $RGList = Get-AzureRmResourceGroup;
    Write-Host("Resource Group not found. Please try again.")-ForegroundColor Yellow;
    Write-Host("Show List of Resource Groups? y/n")-ForegroundColor White;
    $bool = Read-Host;
    if($bool -eq 'y') #---- If desired dispalys all known Resoure Groups.
    {
        Foreach ($i in $RGList)
        {
            Write-Host $i.ResourceGroupName;
        }
    }
	$groupname = Read-Host("Enter Resource group name.");
	Get-AzureRmResourceGroup -Name $groupname -ev exists -ea 0;
	}
	Write-Host("Resource group $groupname found. Continuing.")-Foregroundcolor green;
	return $groupname; #----- Returns correct Resource Group name as String.
}
#----- Gets Azure Application value from user and verifies its existance.
function GetAzureRmAppId
{
	$valid=$FALSE;
    $temp=Get-AzureRmADApplication; #---temp list of Azure Rm Applications (and their id's)
	while (! $valid)
	{
        $valid=$TRUE;
        Write-Host ("Enter a unique Azure Rm Ad App Id (homepage) for this service: ");
        Write-Host ("Example: http://localhost:xxxx");
        $name = Read-Host;
        while($name -eq '')
        {
            Write-Host ("Please enter the Azure Rm Ad App Id (Cannot be blank): ")-ForegroundColor Yellow;
            $name = Read-Host;
        }

        ForEach ($i in $temp)
        {

            if ($i.HomePage -eq $name -or $i.IdentifierUris -eq $name)
            {
                $valid=$FALSE;
                write-host ("Duplicate name found!")-ForegroundColor Yellow;
            }
        }
        if (!$valid)
            {
                write-Host "Display known HomePage/Uri Names? y/n";
                $a=Read-Host;
                if($a -eq 'y')
                {
                    ForEach ($i in $temp)
                    {
                        if ($i.HomePage -eq $name -or $i.IdentifierUris -eq $name)
                        {
                            write-host $i.HomePage -ForegroundColor Yellow;
                            write-host $i.$i.IdentifierUris -ForegroundColor Yellow;
                        }
                        else
                        {
                            write-host $i.HomePage -ForegroundColor White;
                            write-host $i.$i.IdentifierUris -ForegroundColor white;
                        }
                    }
                }
            }
        }
Write-Host ("Name is unique - continuing")-ForegroundColor Green;
return $name;
}
#----- Gets AzureAppRole Name from user and verifies it is unique.
function GetAzureApplicationRoleName
{
    $valid = $FALSE;
    $temp=Get-AzureRmRoleDefinition;
    while(! $valid)
    {
        Write-Host "Please enter a -unique- Azure Application Role Name"
        $name=Read-Host;
         while($name -eq '')
        {
            Write-Host ("Please enter Azure Application Role Name( Cannot be blank): ")-ForegroundColor Yellow;
            $name = Read-Host;
        }

        $valid=$TRUE;
        ForEach ($i in $temp)
        {
            if ($i.name -eq $name)
            {
                $valid=$FALSE;
                write-host ("Duplicate name found!")-ForegroundColor Yellow;
            }
        }
           if (!$valid)
           {
                write-Host "Display known Role Names? y/n";
                $a=Read-Host;
                if($a -eq 'y')
                {
                    ForEach ($i in $temp)
                    {
                        write-host $i.name;
                    }
                    Write-Host " ";
                }
            }
    }
    Write-Host ("Name is unique! Continuing")-ForegroundColor Green;
    return $name;
}
#----- Generates the End day for the uploaded certificate from the certificate end date
function Generate_EndDate
{
	Param($cert);
	Write-Host ("Fetching end date from certificate...");
	Write-Host ("");
	$endDate = [System.DateTime]::Parse($cert.GetExpirationDateString())
	## subtract a day
	$subtractNumDays = 1
	$timespan = New-TimeSpan -Days $subtractNumDays
	$endDate = $endDate - $timespan
  	Write-Host ("... end date retrieved successfuly")-ForegroundColor Green;
	return $endDate;
}

############################
#Main program starts here. #
############################

#-----Greeting
Greeting;
#------Login to Azure
#------Login is done here and not in a function, as it seems the login creds are lost after the data is returned. Seems to be a bug on Azure end.
$successful=$FALSE; #Sets succeful to false for while loop.
$num_tries=0;
$max_auth_tries = 3;
while(!$successful) # Repeats until user is able to log into Azure correctly.
{
$successful = $TRUE; # successful is now true unless otherwise found to be false inside the loop.
    try #try to login to Azure error if unable able to login.
    {
        $loginResult=Login-AzureRmAccount -ErrorVariable err -ErrorAction Stop;
    }
    catch #catch login error and prompt for another attempt.
    {
        $successful=$FALSE;
				$num_tries++;
        Write-Host ("Authentication failed.")-ForegroundColor Yellow;
				if($num_tries -eq $max_auth_tries)
				{
					Write-Host ("Authentication failed too many times.")-ForegroundColor Red;
					exit;
				}

    }
}
Write-host ($loginResult);
#-----Check for certificate file (Arm.cer)
$pathToCERfile = CheckCERFile;
#-----Set Subscription to default subscription for the current login. Exit on error (no subscription found)
try
{
	$subcriptionID = (Get-AzureRmContext -ErrorVariable err -ErrorAction Stop).Subscription.SubscriptionId;
}
catch
{
	Write-Host ($err);
	exit;
}# If there is no SubscriptionId script exit.

#-----Set Azure RM Subscription.
Write-Host("Setting current Azure Rm Subscription...");
try
{
	$azureSubscription = Select-AzureRmSubscription -SubscriptionId $subcriptionID -ErrorVariable err -ErrorAction Stop;
}
catch
{
Write-Host ("*** WARNING!***")-ForegroundColor Yellow;
Write-Host ("There was an error selecting subsciption ID, one may not exist with this account.")-ForegroundColor Yellow;
if (!$subcriptionID)
{
Write-Host ("Subscription ID returned result: NULL")-ForegroundColor Yellow;
}
else
{
Write-Host ("Subscription ID returned result:",$subcriptionID)-ForegroundColor Yellow;
}
Write-Host ("This is an unrecoverable error. Exiting Script") -ForegroundColor Red;
#Break;
}# If there is no SubscriptionId scrip exits.
Write-Host("Azure subscription found and set as: $subscriptionID.")
Write-Host("...setting current Azure subscription Completed.")-ForegroundColor Green;
#-----Get Reource Group Name;
$resourceGroupName = GetResourceGroup;
#-----Get Reource Application Identifier;
$identifier = GetAzureRmAppId;
#-----Get Reource Application Name;
$rolename = GetAzureApplicationRoleName;

# Create a custom role for NGF Cloud Integration. An existing role is cloned, all rights removed and then assigned proper privileges
write-Host ("Role Generation Started...");
#---Generates a Azure Role Definition and assigns approperiate values.
$role = Get-AzureRmRoleDefinition "Virtual Machine Contributor"
$role.Id = $null
$role.Name = $roleName
$role.Description = "Barracuda NextGen Firewall Cloud Integration"
$role.Actions.Clear()
# Add role definitions to the empty role
$role.Actions.Add("Microsoft.Compute/virtualMachines/*")
$role.Actions.Add("Microsoft.Network/*")
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/"+$subcriptionID.ToString());
#-----

#----- Converts the role definttion to legitimate role object.
$firewallRole = New-AzureRmRoleDefinition -Role $role

#-----Generates certificate and pulls key from certificate.
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate($pathToCERfile)
$key = [System.Convert]::ToBase64String($cert.GetRawCertData())

#-----Certificate Generation
$endDate= Generate_EndDate($cert); #-----Expire date for certificate.

#---Creating Princial account for use in Azure.
Write-Host ("Generation of Service Principal account started...");
try{
	$app = New-AzureRmADApplication -DisplayName $ADAppName -HomePage $identifier.ToString() -IdentifierUris $identifier -CertValue $key -EndDate $endDate -ErrorAction Stop;
	$prince = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId -ErrorAction Stop;
}
catch
{
	Write-Host ("Error generating Service Principal")-ForegroundColor Green;
	Write-Host ("'Exception Message ''{0}''' -f $_.Exception.Message");
	Write-Host ("'Exception Item Name ''{0}''' -f $_.Exception.ItemName");
	exit;
}
Write-Host ("...Generation of Serivce Principal account completed")-ForegroundColor Green;

# Wait for Azure to generate service principal
Write-Host("Sleeping for 30 seconds while Azure generates new service principal remotely.")
Start-Sleep -Seconds 30;
#Upload Service Principal
write-host("Generating Service Principal for Azure.");
$newRole=New-AzureRmRoleAssignment -RoleDefinitionName $firewallRole.Name -ServicePrincipalName $prince.ServicePrincipalNames[0]
write-host("Generating Service Pricipal Completed.")-ForegroundColor Green;
#-----Exit Successfuly
Write-Host ("Use the following information to configure Azure Cloud Integration on your NextGen Firewall F:");
write-host ("Subscription ID: ");
write-host (Get-AzureRmContext).Subscription.SubscriptionId -ForegroundColor Green;
write-host ("Tenant ID: ");
write-host (Get-AzureRmContext).Tenant.TenantId -ForegroundColor Green;
write-host ("Application ID: ");
write-host ($app.ApplicationId) -ForegroundColor Green;
write-host ("Resource Group: ");
write-host ($resourceGroupName) -ForegroundColor Green;
