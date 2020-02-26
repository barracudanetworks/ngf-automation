        <#
            .DESCRIPTION
               This is an example runbook that can be used in combination with a webhook that can be triggered by the 
               Barracuda NGF to perform additional actions upon failover.
               In this case this example script updates all the route tables in resource groups that the NGF service 
               principal has been given access too.

            .NOTES
                AUTHOR: Gemma Allen (gallen@barracuda.com)
                LASTEDIT: 25 April 2019
                v1 - first attempt, very basic authentication being used. Removed from being a workflow.
        #>
    param(
    [object]$WebhookData
    )
    #This script is in test mode by default, remove the leading # to comment out lines 22,23 & 24. 
	#fill in the details for the webhookbody with your test data if you are not using the webhook
    #<#
    $testmode = $true
    $webhookData = "data"
    $nowebhook = $true
    #>

	#Set this to the name of your Azure Automation Connection that works with the NGF service principal

	# Credential for accessing the ERCS PrivilegedEndpoint, typically domain\cloudadmin
	#Run once to provide a cred file. 
	#read-host -assecurestring | convertfrom-securestring | out-file C:\mysecurestring.txt

	$username = "AzureStack\CloudAdmin"
	$password = Get-Content 'C:\mysecurestring.txt' | ConvertTo-SecureString 
	$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
	$stackArmEndpoint = "https://management.local.azurestack.external"
	$stackEnvironmentName = "AzureStackUser"
    #$ResourceGroup = "<YOURAUTOMATIONRESOURCEGROUP>"

    if($webhookData -ne $null){
            
# Collect properties of WebhookData.
        Write-Output $WebHookData

        $WebhookName    =   $WebhookData.WebhookName
        $WebhookBody    =   $WebhookData.RequestBody
        $WebhookHeaders =   $WebhookData.RequestHeader

        # Outputs information on the webhook name that called This
        Write-Output "This runbook was started from webhook $WebhookName."
         if($nowebhook){
         #The below can be edited to replicate your NGF's IP's and subscription details 
         #it doesn't need commenting out as the section under line #18 enables this
          $WebhookBody = '[
{ 
"SubscriptionId" : "75e9e30b-621f-4cd4-ac37-0a3a8b3b7c89",
"id": "NGF",
"properties" :{
	"OldNextHopIP" :  "10.78.1.12",
	"NewNextHopIP" : "10.78.1.13"
}
}
]'

}

        # Obtain the WebhookBody containing the data to change
        try{

#When testing without the NGF you can fill in the below and uncomment the second ConvertedJson line to test
           
            Write-Output "`nWEBHOOK BODY IN"
            Write-Output "============="
            Write-Output $WebhookBody

            if($nowebhook){
			    #The below line is used in combination with the Webhookbody variable commented out.
			    $ConvertedJson = ConvertFrom-Json -InputObject $WebhookBody
            }else{
			    #I'm sure there's a better way, but this works. As it's JSON in JSON I had double convert from the body. 
                $ConvertedJson = ConvertFrom-Json -InputObject (ConvertFrom-Json -InputObject $WebhookBody)
            }
            Write-Output "`nWEBHOOK BODY OUT"
            Write-Output "============="
            Write-Output $ConvertedJson
            Write-Output "JSON Sub" $ConvertedJson.SubscriptionId
		#	if($ConvertedJson.SubscriptionId -eq "secondnic"){Write-Output "Script triggered on behalf of second NIC will act upon all Subs"}

        }catch{
            if (!$ConvertedJson)
            {
                Write-Error -Message $_.Exception
                $ErrorMessage = "No body found."
                throw $ErrorMessage
            } else{
                Write-Error -Message $_.Exception
                throw $_.Exception
            }
        }

        try
        {
            # Get the connection "AzureRunAsConnection "

           # $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName    
           # Write-Output ($servicePrincipalConnection.TenantId)
           # Write-Output ($servicePrincipalConnection.ApplicationId)
           # Write-Output ($servicePrincipalConnection.CertificateThumbprint)    
         
           # Write-Output "Subscription: $subsid"
           Write-Output "Logging in to AzureStack..."
		   	# Register an Azure Resource Manager environment that targets your Azure Stack instance
			Add-AzureRMEnvironment -Name "AzureStackUser" -ArmEndpoint "$($stackArmEndpoint)"

			# Sign in to your environment 
			Login-AzureRmAccount -EnvironmentName "$($stackEnvironmentName)" -Credential $cred

            #Add-AzureRMAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantID `
             #   -ApplicationId $servicePrincipalConnection.ApplicationID -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
            
           

        }catch {
                Write-Error -Message $_.Exception
                throw $_.Exception
        }

		#Get's NGF's local subscription and NextHopIP's
        $nexthopip = ($ConvertedJson | Where -Property SubscriptionId -eq $ConvertedJson.SubscriptionId | Select-Object -ExpandProperty Properties).NewNextHopIP
        $oldhopip = ($ConvertedJson | Where -Property SubscriptionId -eq $ConvertedJson.SubscriptionId | Select-Object -ExpandProperty Properties).OldNextHopIP
        Write-Output = "Old Hop IP: $oldhopip "
        Write-Output = "Next Hop IP: $nexthopip "

       # $existing_status = (Get-AzureRmAutomationVariable -Name Update_UDR_status -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccount).Value
      #  Write-Output "Collected existing status of: $existing_status"

        
		#if and IP is provided and it's not exactly the same as another script that's running currently
		if($nexthopip){
		#	$subscriptions = Get-AzureRMSubscription -WarningAction 'silentlycontinue'
          #  Set-AzureRmAutomationVariable -Name "Update_UDR_status" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccount -Value "running:$($oldhopip):$($nexthopip)" -Encrypted $false
		#    Write-Output "Updating status variable with running:$($oldhopip):$($nexthopip)"
#
			#ForEach($sub in $subscriptions){
            
				Write-Output "Azure Stack Sub ID" $ConvertedJson.SubscriptionId

				Select-AzureRMSubscription -SubscriptionId $ConvertedJson.SubscriptionId

                #Authorise to the AzureAPI
             <#   $formData = @{
                  client_id = $servicePrincipalConnection.ApplicationID;
                  client_secret = $($secret);
                  grant_type = 'client_credentials';
                  resource = "https://management.azure.com/";

                }
                if($testmode){
                    Write-Output("FormData "+ $formData)
                }

                $uri = 'https://login.microsoftonline.com/'+$servicePrincipalConnection.TenantID+'/oauth2/token?api-version=1.0'
                try{
                   $response = Invoke-RestMethod -Uri $uri -Method Post -Body $formData -ContentType "application/x-www-form-urlencoded"     
                }catch{
                    Write-Error ("Unable to authenticate because:" + $_.Exception)
                }
                
                if($testmode){
                    Write-Output("AccessToken: "+ $response.access_token)
                }

                if(!$response.access_token){
                    Write-Error "No access token from authentication"
                    Exit 1 
                }

                #Set's the authorisation header
                $headers = @{"Authorization"="$($response.token_type) $($response.access_token)"; "Content-Type"="application/json"} 
                #>

                #doesn't act on the subscription the NGF belongs to.
				#CHANGE TO -ne 
				#if($sub.SubscriptionId -ne $ConvertedJson.SubscriptionId){
                
	                    #Reviews the properties and ensures the route tables only get selected which contain the old firewall IP.
                        
						#$Resources = Find-AzureRmResource -ResourceType "Microsoft.Network/routeTables" -ExpandProperties | Where-Object -FilterScript {$_.Properties.routes.properties.nextHopIpAddress -eq "$oldhopip"} | Select ResourceName, ResourceType, ResourceId, SubscriptionId, ResourceGroupName
                        #For newer versions use the below, for old use the above.
                        $Resources = Get-AzureRmResource -ODataQuery "`$filter=resourcetype eq 'Microsoft.Network/routeTables'" -ExpandProperties | Where-Object -FilterScript {$_.Properties.routes.properties.nextHopIpAddress -eq "$oldhopip"} | Select ResourceName, ResourceType, ResourceId, SubscriptionId, ResourceGroupName
                        
                        if($Resources.Length -eq 0){
                            Write-Warning ("No Routetables found containing " + $oldhopip + "so script aborting")
                        }else{
                                                    if($testmode){
                                Write-Output("Running in Test mode for extra reporting")
                            }

							ForEach ($Resource in $Resources)  
								{
									Write-Output ($Resource.ResourceName + " of type " +  $Resource.ResourceType + "in" + $Resource.ResourceGroupName)
									try{
										#Had to move the code working on the route tables into an inline script due to workflow deserialisation preventing the $rt remaining a PSRouteObject
                                    
										
                                            
                                            $rt = Get-AzureRmRouteTable -Name $Resource.ResourceName -ResourceGroupName $Resource.ResourceGroupName 
                                            
                     
                                            $madechange = 0


											For($i=0; $i -lt $rt.Routes.Count; $i++){
                                            
												#Checks the current NextHopIP is the inactive members
												if($rt.Routes[$i].NextHopIPAddress -eq $oldhopip){
                                                    #Makes a record of what the NextHop used to be. 
    												$fromold = $rt.Routes[$i].NextHopIpAddress	

                                                    #Updates the route with the new nextHopIP
                        							$rt.Routes[$i].NextHopIpAddress = $nexthopip 
                                                    
													$madechange++; 
												}
                                            
											}
											try{
												if($madechange -ne 0){
                                                    #Comment the below line out to not make any real changes
                                                    
                                                    if($testmode){
                                                        $result = Set-AzureRmRouteTable -RouteTable $rt
                                                    }
                                                    #Comment the below line out to stop the test mode reporting
                                                    $result = "Change to" + $rt.Name + " From NextHop: " + $fromold + " To NextHop: " + $nexthopip
												
                                                }else{
													$result = "No changes required to as NextHops already match or are not for this cluster in: " + $rt.Name
												}
											}catch{
												$result = $_.Exception
											}
											$result
							

										#Write-Output $routechange
										if($routechange.ProvisioningState -eq 'Succeeded'){
											Write-Output("Success for " + $routechange.Name)
                                            #Write-Output($routechange)
										}else{
                                            if($testmode){
                                                Write-Output("This runbook didn't update because: it's in TEST MODE" )
                                            }else{
											    Write-Output("This runbook didn't update because: " + $routechange )
                                            }
										}
  
									}catch{
										Write-Error -Message $_.Exception
                                    
									}
                                    #>
                            
								}#End foreach parallel
                        
							
                                #Empties resources of values before the next Sub get's queried.
                                $Resources=""
								Write-Output ("Script completed")
                                
                            
                                }
						 
				#}else{Write-Warning -Message "Not acting as this subscription is under NGF management"} #End if not local subscription
			#}        #End subscriptions foreach
            #Set-AzureRmAutomationVariable -Name "Update_UDR_status" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccount -Value "completed:$($oldhopip):$($nexthopip)" -Encrypted $false
		}else{#If nexthopip found
			#Write-Error -Message "No nexthop IP found in webhook data or script running: $($existing_status)"
            #Set-AzureRmAutomationVariable -Name "Update_UDR_status" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccount -Value "failed" -Encrypted $false
		}
    }else{
        Write-Error -Message "This runbook is intended to be started by webhook only" 
       # Set-AzureRmAutomationVariable -Name "Update_UDR_status" -ResourceGroupName $ResourceGroup -AutomationAccountName $AutomationAccount -Value "failed" -Encrypted $false
    }#end if webhook data
