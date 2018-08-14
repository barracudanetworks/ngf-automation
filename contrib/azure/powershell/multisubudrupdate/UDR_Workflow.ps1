workflow Update_UDR
{
        <#
            .DESCRIPTION
               This is an example runbook that can be used in combination with a webhook that can be triggered by the 
               Barracuda NGF to perform additional actions upon failover.
               In this case this example script updates all the route tables in resource groups that the NGF service 
               principal has been given access too.

            .NOTES
                AUTHOR: Gemma Allen (gallen@barracuda.com)
                LASTEDIT: 14 August 2018
                v2 . Updated to use the REST API to make changes to the route tables rather than an inline script.
				v2.1 Minor updates to improve debugging when API calls fail
				v2.2 Updated to latest API for new disableBGPPropagation setting
				v2.3 updated to add retry mechanism
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
    $connectionName = "yourconnectionName"

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
"SubscriptionId" : "a31de56f1-2324-43ae-bdf7-2c229adf2f7f",
"id": "NGF",
"properties" :{
	"OldNextHopIP" :  "10.2.0.8",
	"NewNextHopIP" : "10.2.0.7"
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
			if($ConvertedJson.SubscriptionId -eq "secondnic"){Write-Output "Script triggered on behalf of second NIC will act upon all Subs"}

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

            $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName    
        #    Write-Output ($servicePrincipalConnection.TenantId)
        #    Write-Output ($servicePrincipalConnection.ApplicationId)
        #    Write-Output ($servicePrincipalConnection.CertificateThumbprint)    
         
           # Write-Output "Subscription: $subsid"
           Write-Output "Logging in to Azure..."

            Add-AzureRMAccount -ServicePrincipal -Tenant $servicePrincipalConnection.TenantID `
                -ApplicationId $servicePrincipalConnection.ApplicationID -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
            
           

        }catch {
            if (!$servicePrincipalConnection)
            {
                $ErrorMessage = "Connection $connectionName not found."
                throw $ErrorMessage
            } else{
                Write-Error -Message $_.Exception
                throw $_.Exception
            }
        }

		#Get's NGF's local subscription and NextHopIP's
        $nexthopip = ($ConvertedJson | Where -Property SubscriptionId -eq $ConvertedJson.SubscriptionId | Select-Object -ExpandProperty Properties).NewNextHopIP
        $oldhopip = ($ConvertedJson | Where -Property SubscriptionId -eq $ConvertedJson.SubscriptionId | Select-Object -ExpandProperty Properties).OldNextHopIP
        Write-Output = "Old Hop IP: $oldhopip "
        Write-Output = "Next Hop IP: $nexthopip "
        
		#Not much point continuing without an IP to change to
		if($nexthopip){
			$subscriptions = Get-AzureRMSubscription -WarningAction 'silentlycontinue'
		   # Write-Output $subscriptions

			ForEach($sub in $subscriptions){
            
				Write-Output "Azure Sub ID" $sub.SubscriptionId

				Select-AzureRMSubscription -SubscriptionId $sub.SubscriptionId

                #Authorise to the AzureAPI
                $formData = @{
                  client_id = $servicePrincipalConnection.ApplicationID;
                  client_secret = $(Get-AutomationVariable -Name 'CGFFailoverkey');
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

                #doesn't act on the subscription the NGF belongs to.
				#CHANGE TO -ne 
				if($sub.SubscriptionId -ne $ConvertedJson.SubscriptionId){
                
	                    #Reviews the properties and ensures the route tables only get selected which contain the old firewall IP.
                        $Resources = Find-AzureRmResource -ResourceType "Microsoft.Network/routeTables" -ExpandProperties | Where-Object -FilterScript {$_.Properties.routes.properties.nextHopIpAddress -eq "$oldhopip"} | Select ResourceName, ResourceType, ResourceId, SubscriptionId, ResourceGroupName
                        
                        if($Resources.Length -eq 0){
                            Write-Warning ("No Routetables found containing " + $oldhopip + "so script aborting")
                        }else{

                            if($testmode){
                                Write-Output("Running in Test mode for extra reporting")
                            }
								ForEach -Parallel ($Resource in $Resources)  
								{
									Write-Output ($Resource.ResourceName + " of type " +  $Resource.ResourceType + "in" + $Resource.ResourceGroupName)
									try{
										#Revised to call the API directly, edit the JSON and post back the response, so should all be able to operate in workflow.
                                        
                                        Write-Output ("Updating Resource: " + $Resource.ResourceName + " in ResourceGroup: " +  $Resource.ResourceGroupName)
                                        #Sets the routetableuri to call
                                        $routetableuri = "https://management.azure.com/subscriptions/$($sub.SubscriptionId)/resourceGroups/$($Resource.ResourceGroupName)/providers/Microsoft.Network/routeTables/$($Resource.ResourceName)?api-version=2018-01-01"

                                        if($testmode){
                                            
                                            Write-Output("RouteTable URI:" + $routetableuri)
                                            try{
                                            $results = Invoke-RestMethod -Uri $routetableuri -Method GET -Headers $headers | ConvertTo-Json -Depth 20
                                            }catch{
                                                Write-Error("Failed to read" + $Resource.ResourceName + "due to " + $_.Exception)
                                            }
                                            Write-Output("Results of the REST GET: " + $results)
                                            
                                            #Replaces the contents of the Json from the old IP to the new
                                            $out = $results -replace $oldhopip,$nexthopip
                                            Write-Output("Following Replacement of IP: " + $out)
                                       
                                        }else{
                                            try{
                                            #Replaces the contents of the Json from the old IP to the new and PUT's the change into the API.
                                                $results = Invoke-RestMethod -Uri $routetableuri -Method PUT -Headers $headers -Body ((Invoke-RestMethod -Uri $routetableuri -Method GET -Headers $headers | ConvertTo-Json -Depth 20) -replace $oldhopip,$nexthopip)
                                            }catch{
                                                Write-Error("Failed to update" + $routetableuri + "due to " + $_.Exception)
                                            }
                                            Write-Output ("Change to" + $Resource.ResourceName + " From NextHop: " + $fromold + " To NextHop: " + $nexthopip)
                                        }
									    

										#Write-Output $routechange
										if($results.properties.ProvisioningState -eq 'Succeeded' -or $results.properties.ProvisioningState -eq 'Updating'){
											Write-Output("Success for " + $Resource.ResourceName)
                                            #Write-Output($routechange)
										}else{
                                            if(!$testmode){
                                                
                                            
											Write-Output("This runbook didn't update because: " + $results )
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
						  #}#End foreach RG
				}else{Write-Warning -Message "Not acting as this subscription is under NGF management"} #End if not local subscription
			}#End subscriptions foreach
		}else{#If nexthopip found
			Write-Error -Message "No nexthop IP found in webhook data"
		}
    }else{
        Write-Error -Message "This runbook is intented to be started by webhook only" 
    }#end if webhook data
}
