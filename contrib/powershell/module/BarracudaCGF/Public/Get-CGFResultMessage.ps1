Function  Get-BarracudaCGF-ResultMessage{
<#
.Synopsis
	Provides custom messages when API returns results
.Description
    This function is given the input of a HTTP statusCode and returns a printed message to screen/log for that result.

.Example
	GET-BarracudaCGF-ResultMessage 204 
.Notes
v1.0
#>
param(
$results,
$objectname
)
    switch($results){
		"500" { Write-Error "Unable to add entry, check if service is already locked or incorrectly named"; break}
		"403" { Write-Error "Authorisation failed"; break}
		"409" { Write-Output "Existing newtork object found - Replacing object instead"; break	}
		"204" { Write-Output "$($objectname) updated succesfully"; break }
		{$_ -ge 200 -or $_ -le 299} { Write-Output "$($objectname) updated succesfully"; break }
	    default{	 Write-Output "$($results)"; break;       }
		}


}