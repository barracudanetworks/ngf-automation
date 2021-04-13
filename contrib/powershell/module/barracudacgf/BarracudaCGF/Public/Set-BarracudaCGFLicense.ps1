<#
.Synopsis
	Performs a License Activation for a Firewall
.Description
    This function should provide the license token 
.Example

    Please don't use the data here, or fake information when trying to activate a box. 
    Set-BarracudaCGFLicense -deviceName $dev_name -devicePort $dev_port -notHTTPs -username $creds.UserName -password $creds.Password. -acceptTAC $true `
    -address "Kings Rd" -city "Reading" -companyName "Barracuda" -country "United Kingdom" -emailAddress "gallen@barracuda.com" -state "Berkshire" -zip "RG1 3AR" `
    -firstName "Firstname" -lastName "Lastname" -phoneNumber "0118111111" -licenseToken "ABCDE-FGHIJ-KLMNP" `
    -purchaseCity "Reading" -purchaseCountry "United Kingdom" -purchaseemailAddress "gallen@barracuda.com" -purchasePhone "0118" -purchasedFrom "Barracuda Networks" -salePersonName "Salesperson Name" `
    -purchaseState "Berkshire" -purchaseZip "RG1 3AR" -Debug 
.Notes
v0.1
#>

Function Set-BarracudaCGFLicense {
    [cmdletbinding()]
#If none of these are supplied it returns the code

    param(
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$deviceName,

        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$false)]
        [string] $username,
        
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$false)]
        [securestring] $password,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string] $devicePort=8443,

#below parameters are used to define the api path being used. contain settings for CC, forwarding or host ruleset.
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [bool]$acceptTAC=$true,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$address,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$city,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$companyName,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$country,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$emailAddress,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$state,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$zip,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$firstName,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$lastName,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$phoneNumber,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$licenseToken,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$purchaseCity,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$purchaseCountry,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$purchaseemailAddress,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$purchasePhoneNumber,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$purchasedFrom,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$salePersonName,

        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$purchaseState,
        [Parameter(Mandatory=$false,
        ValueFromPipelineByPropertyName=$true)]
        [string]$purchaseZip,
        [Parameter(Mandatory=$false,
    ValueFromPipelineByPropertyName=$true)]
[switch]$notHTTPs

        
    )

    #Check Pwrshell version is 7.
    if($PSVersionTable.PSVersion.Major -lt 7){
        Write-Error -Message "This function requires Powershell 7.1 or above to translate the password from a secure string"
    }
    
    #makes the connection HTTPS
    if(!$notHTTPS){
        $s = "s"
    }


    If ($PSBoundParameters['Debug']) {
        $DebugPreference = 'Continue'
    }
    if($range -and !$cluster){
        Write-Error "Partial Control Center information supplied, please change range, cluster and box info"
    }

    Write-Debug "Provide PSBoundParameters"

   #sets any default variables to parameters in $PSBoundParameters
    foreach($key in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $value = Get-Variable $key -ValueOnly -EA SilentlyContinue
        if($value -and !$PSBoundParameters.ContainsKey($key)) {$PSBoundParameters[$key] = $value}
        Write-Debug "$($key) : $($value)"
    }


    $customerInformation += @{address=$address;city=$city;companyName=$companyName;country=$country;emailAddress=$emailAddress;firstName=$firstName;lastName=$lastName;phoneNumber=$phoneNumber;state=$state;zip=$zip}
    $purchaseInformation += @{city=$purchasecity;purchasedFrom=$purchasedFrom;country=$purchaseCountry;emailAddress=$purchaseemailAddress;salespersonName=$salePersonName;phoneNumber=$purchasephoneNumber;state=$purchasestate;zip=$purchasezip}
    
   
   
    

    #builds the paramters to be posted
    $postParams = @{}
    $postParams.Add("acceptTAC",$acceptTAC)
    $postParams.Add("customerInformation",$customerInformation)
    $postParams.Add("licenseToken",$licenseToken)
    $postParams.Add("password",(ConvertFrom-SecureString -SecureString $password -AsPlainText))
    $postParams.Add("purchaseInformation",$purchaseInformation)
    $postParams.Add("username",$username)
    
    
    #Converts to JSON
    $data = ConvertTo-Json $postParams -Depth 99
    
    
    #Sets the token header
    $header = @{"X-API-Token" = "$token"}

    Write-Debug $url
    Write-Debug $data

    if(!$deviceName -and !$token){
        return $postParams

    }else{

        
            try{
                $results = Invoke-WebRequest -Uri "http$($s)://$($deviceName):$($devicePort)/rest/control/v1/box/licenses/activate"  -ContentType 'application/json' -Method POST -Headers $header -Body $data -UseBasicParsing -SkipCertificateCheck
            }catch [System.Net.WebException] {
                    $results = [system.String]::Join(" ", ($_ | Get-ExceptionResponse))
                    Write-Error $results
                     
            }


    }

return $results
}