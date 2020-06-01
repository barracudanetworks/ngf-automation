function Get-ExceptionResponse {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

    process {
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            if ($InputObject.Exception.Response) {  
                $reader = New-Object -TypeName 'System.IO.StreamReader' -ArgumentList $_.Exception.Response.GetResponseStream()
                
                $reader.BaseStream.Position = 0
                $reader.DiscardBufferedData()
                
                $reader.ReadToEnd()

                $response = $reader.ReadToEnd() | ConvertFrom-Json
                
            }
        }
        else {
            $_.ErrorDetails.Message
        }
    }
    
}