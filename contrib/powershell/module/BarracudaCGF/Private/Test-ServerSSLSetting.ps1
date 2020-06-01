function Test-ServerSSLSupport {
[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$HostName,
        [UInt16]$Port = 443,
        [boolean]$MoreInfo = $false
    )
    process {
        $RetValue = New-Object psobject -Property ([ordered]@{
            Host = $HostName
            Port = $Port
            KeyExhange = $null
            HashAlgorithm = $null
            SSLv2 = $false
            SSLv3 = $false
            TLSv1_0 = $false
            TLSv1_1 = $false
            TLSv1_2 = $false
        })
        "ssl2", "ssl3", "tls", "tls11", "tls12" | %{
            $TcpClient = New-Object Net.Sockets.TcpClient
            try {$TcpClient.Connect($RetValue.Host, $RetValue.Port)}
            catch {Write-Host "`nThe host $HostName does not exist or not responding on port $Port `n" -ForegroundColor RED; break}
            $SslStream = New-Object -TypeName Net.Security.SslStream -ArgumentList $TcpClient.GetStream(), $true,([System.Net.Security.RemoteCertificateValidationCallback]{$true})
            $SslStream.ReadTimeout = 15000
            $SslStream.WriteTimeout = 15000
            try {
                $SslStream.AuthenticateAsClient($RetValue.Host,$null,$_,$false)
                $RetValue.KeyExhange = $SslStream.KeyExchangeAlgorithm
                $RetValue.HashAlgorithm = $SslStream.HashAlgorithm
                $status = $true
            } catch {
                $status = $false
            }
            switch ($_) {
                "ssl2" {$RetValue.SSLv2 = $status}
                "ssl3" {$RetValue.SSLv3 = $status}
                "tls" {$RetValue.TLSv1_0 = $status}
                "tls11" {$RetValue.TLSv1_1 = $status}
                "tls12" {$RetValue.TLSv1_2 = $status}
            }
            switch ($retvalue.KeyExhange) {
            "44550" {$RetValue.KeyExhange = "ECDH_Ephem"}
            }
            If ($MoreInfo -eq $true) {
            "From "+ $TcpClient.client.LocalEndPoint.address.IPAddressToString +" to $hostname "+ $TcpClient.client.RemoteEndPoint.address.IPAddressToString +':'+$TcpClient.client.RemoteEndPoint.port
            $SslStream |gm |?{$_.MemberType -match 'Property'}|Select-Object Name |%{$_.Name +': '+ $sslStream.($_.name)}
            }
            # dispose objects to prevent memory leaks
            $TcpClient.Dispose()
            $SslStream.Dispose()
        }
        $RetValue
    }
}