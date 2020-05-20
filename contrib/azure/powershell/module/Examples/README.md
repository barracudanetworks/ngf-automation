
# Example using the AzureFW to Barracuda conversion script with Control Center managed firewalls

This script will take the Azure firewall ruleset and transfer it into a Barracuda ruleset. Currently the script only creates the firewall rules. 

It can be ran online of offline (via the provision of CSV files), when online you need to login to Azure first and supply details for the Azure FW to take the rules from. The script will query for what it requires.



```powershell

Set-BarracudaCGFtoIgnoreSelfSignedCerts -allowSelfSigned -noCRL

#Create a rule list to import this into - define the name

#$firewallname = "GA-AZ-FIREWALL"
#$fwresourcegroup = "GA-Ncus-TESTRG"

$barracudacc = "youriphere"
$barracudacctoken = "tokenhere"

$cluster = "NorthCentralUS8" #This is the CC Cluster that my firewall is managed in
$range = 1  #This is the CC range
#$devicePort = 8443 # -left this commented out ast the default is 8443
$box = "MYFIREWALLNAME" #The name of your firewall
$servicename = "NGFW" #The service of the firewall ruleset if different. 
#In this example I create a seperate rule list to insert my imported rules into. I could remove the -listname $rulelist name below and write direct to the main firewall ruleset.
$rulelistname = "AzureFWRul" 

#This example uses offline firewall rules and IP groups in a CSV format
$offlinesourcefile = ".\FirewallRules.csv"
$offlineipgroupfile = ".\ipg.csv"
$offlineaction = "Allow"

#Uncomment these if you want loads of info!
#$VerbosePreference = "Continue"
#$DebugPreference = "SilentlyContinue"

./AzureFW_to_BarracudaCGF_Conversion.ps1 -deviceName $barracudacc -token $barracudacctoken -range $range -cluster $cluster -serviceName $servicename -box $box `
-listName $rulelistname -offlinesourcefile $offlinesourcefile -offlineipgroupfile $offlineipgroupfile -offlineaction Allow -removeduplicates $true 

```