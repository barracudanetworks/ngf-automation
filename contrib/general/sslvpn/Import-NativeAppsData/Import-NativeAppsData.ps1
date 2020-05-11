#Delete "CGFW_SSLVPN_NativeApp_Settings.txt"
If ((Test-Path -Path "CGFW_SSLVPN_NativeApp_Settings.txt") -eq $True) {
    Rename-Item -Path "CGFW_SSLVPN_NativeApp_Settings.txt" -NewName "CGFW_SSLVPN_NativeApp_Settings_$(Get-Date -Format ddMMyyyy_HHMMss).txt"
}
#Create an empty file to output the configuration for the firewall
New-Item -Path "CGFW_SSLVPN_NativeApp_Settings.txt"
#Convert the CudaLaunch NativeApp Spreadsheet to a CSV
#
#Import the CudaLaunch NativeApp CSV
$Settings = Import-Csv -Path "CudaLaunch.csv"
Add-Content -Path "CGFW_SSLVPN_NativeApp_Settings.txt" -Value 'CONFDEF server/sslvpn/sslvpn partial 8.0'
ForEach($setting in $settings) {
    #Basic Configuration Properties
    #Set the name for the NativeApp
    $SECPORTFWDSEC = "[secportfwdsec_" + $setting.FirstandLastName + "]"
    #Names of NativeApps cannot contain the space character
    $SECPORTFWDSEC = $SECPORTFWDSEC.Replace(' ','')
    #Enable the NativeApp
    $SECPORTFWDENABLE = 'SECPORTFWDENABLE = 1'
    #Set the CudaLaunch displaed NativeApp name
    $SECPORTFWDVISIBLENAME = 'SECPORTFWDVISIBLENAME = ' + $setting.FirstandLastName + ' (' + $setting.ComputerName + ')'
    #Set the NativeApp IP Address
    $SECPORTFWDADDR = 'SECPORTFWDADDR = ' + $setting.ComputerIPAddress
    #Set the port $setting.ComputerName uses to listen for Remote Desktop Protocol connections
    $SECPORTFWDPORT = 'SECPORTFWDPORT = 3389'
    #Set the port number the local host will use for port forwarding Remote Desktop Protocol traffic to $setting.ComputerName
    $SECPORTFWDLOCALPORT = 'SECPORTFWDLOCALPORT = 0'
    #Set the Active Directory Security Group Distinguished Name which is authorized to use the NativeApp
    $SECPORTFWDGROUP ='SECPORTFWDGROUP[0] = ' + $setting.ADSecurityGroupDistinguishedName
    #$SECPORTFWDICON = ''
    #$SECPORTFWDICONFILENAME = ''
    $SECPORTFWDUSERNAME = 'SECPORTFWDUSERNAME = ${session:username}'
    $SECPORTFWDPASSWORD = 'SECPORTFWDPASSWORD = ${session:password}'
    #Set the domain name
    #$SECPORTFWDDOMAIN = 'SECPORTFWDDOMAIN = '
    $SECPORTFWDDOMAIN = $setting.ADSecurityGroupDistinguishedName
    $SECPORTFWDDOMAIN = 'SECPORTFWDDOMAIN = ' + $SECPORTFWDDOMAIN.Split(',=')[9] + '.' + $SECPORTFWDDOMAIN.Split(',=')[11]
    #Advanced Configuration Properties
    $SECPORTFWDNEGSEC = 'SECPORTFWDNEGSEC = '
    $SECPORTFWDNLA = 'SECPORTFWDNLA = '
    $SECPORTFWDAUTORECONN = 'SECPORTFWDAUTORECONN = '
    $SECPORTFWDSCREENSIZE = 'SECPORTFWDSCREENSIZE = '
    $SECPORTFWDCOLORDEPTH = 'SECPORTFWDCOLORDEPTH = '
    $SECPORTFWDSMARTSIZING = 'SECPORTFWDSMARTSIZING = '
    $SECPORTFWDCONNBAR = 'SECPORTFWDCONNBAR = '
    $SECPORTFWDPINCONNBAR = 'SECPORTFWDPINCONNBAR = '
    $SECPORTFWDADMINSESS = 'SECPORTFWDADMINSESS = '
    $SECPORTFWDSPANMON = 'SECPORTFWDSPANMON = '
    $SECPORTFWDMULTIMON = 'SECPORTFWDMULTIMON = '
    $SECPORTFWDREMAUDIO = 'SECPORTFWDREMAUDIO = '
    $SECPORTFWDCAPAUDIO = 'SECPORTFWDCAPAUDIO = '
    $SECPORTFWDKBHOOK = 'SECPORTFWDKBHOOK = '
    $SECPORTFWDREDIRDRIVE = 'SECPORTFWDREDIRDRIVE = '
    $SECPORTFWDREDIRPRINT = 'SECPORTFWDREDIRPRINT = '
    $SECPORTFWDREDIRCOM = 'SECPORTFWDREDIRCOM = '
    $SECPORTFWDREDIRSCARD = 'SECPORTFWDREDIRSCARD = '
    $SECPORTFWDREDIRCLIP = 'SECPORTFWDREDIRCLIP = '
    $SECPORTFWDREDIRPOS = 'SECPORTFWDREDIRPOS = '
    $SECPORTFWDREDIRDEV = 'SECPORTFWDREDIRDEV = '
    $SECPORTFWDCONNTYPE = 'SECPORTFWDCONNTYPE = '
    $SECPORTFWDDETECTBW = 'SECPORTFWDDETECTBW = '
    $SECPORTFWDDETECTNW = 'SECPORTFWDDETECTNW = '
    $SECPORTFWDCOMPRESS = 'SECPORTFWDCOMPRESS = '
    $SECPORTFWDVIDEOMODE = 'SECPORTFWDVIDEOMODE = '
    $SECPORTFWDLAUNCHAPP = 'SECPORTFWDLAUNCHAPP = '
    $SECPORTFWDLAUNCHCWD = 'SECPORTFWDLAUNCHCWD = '
    $SECPORTFWDREMOTEAPP = 'SECPORTFWDREMOTEAPP = '
    $SECPORTFWDREMOTEAPPNAME = 'SECPORTFWDREMOTEAPPNAME = '
    $SECPORTFWDREMOTEAPPPROG = 'SECPORTFWDREMOTEAPPPROG = '
    $SECPORTFWDREMOTEAPPARGS = 'SECPORTFWDREMOTEAPPARGS = '
    $DYNAMICAPP = 'DYNAMICAPP = '
    $DYNAPPALLOWENABLE = 'DYNAPPALLOWENABLE = '
    $DYNAPPALLOWTIMEENABLE = 'DYNAPPALLOWTIMEENABLE = '
    $DYNAPPALLOWDISABLE = 'DYNAPPALLOWDISABLE = '
    $DYNAPPALLOWMAXTIME = 'DYNAPPALLOWMAXTIME = '
    $DYNAPPMAXTIMEDAYS = 'DYNAPPMAXTIMEDAYS = '
    $DYNAPPMAXTIMEHOURS = 'DYNAPPMAXTIMEHOURS = '
    $DYNAPPMAXTIMEMINS = 'DYNAPPMAXTIMEMINS = '
    $DYNAPPALLOWMINTIME = 'DYNAPPALLOWMINTIME = '
    $DYNAPPMINTIMEDAYS = 'DYNAPPMINTIMEDAYS = '
    $DYNAPPMINTIMEHOURS = 'DYNAPPMINTIMEHOURS = '
    $DYNAPPMINTIMEMINS = 'DYNAPPMINTIMEMINS = '

    #Do not change anything past this line.

    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $secportfwdsec
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDENABLE
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDVISIBLENAME
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDADDR
    #Write the configuration for SECPORTFWDSERV to the text file you will import into the Barracuda CloudGen Firewall. This value cannot be changed.
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value 'SECPORTFWDSERV = RDP'
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDPORT
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDLOCALPORT
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDGROUP
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDUSERNAME
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDPASSWORD
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDDOMAIN
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDNEGSEC
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDNLA
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDAUTORECONN
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDSCREENSIZE
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDCOLORDEPTH
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDSMARTSIZING
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDCONNBAR
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDPINCONNBAR
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDADMINSESS
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDSPANMON
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDMULTIMON 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREMAUDIO 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDCAPAUDIO 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDKBHOOK 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREDIRDRIVE 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREDIRPRINT 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREDIRCOM 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREDIRSCARD 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREDIRCLIP 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREDIRPOS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREDIRDEV 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDCONNTYPE 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDDETECTBW 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDDETECTNW 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDCOMPRESS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDVIDEOMODE 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDLAUNCHAPP 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDLAUNCHCWD 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREMOTEAPP 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREMOTEAPPNAME 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREMOTEAPPPROG 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $SECPORTFWDREMOTEAPPARGS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAMICAPP 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPALLOWENABLE 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPALLOWTIMEENABLE 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPALLOWDISABLE 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPALLOWMAXTIME 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPMAXTIMEDAYS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPMAXTIMEHOURS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPMAXTIMEMINS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPALLOWMINTIME 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPMINTIMEDAYS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPMINTIMEHOURS 
    Add-Content "CGFW_SSLVPN_NativeApp_Settings.txt" -Value $DYNAPPMINTIMEMINS 
    }
Invoke-Command -ScriptBlock {notepad.exe "CGFW_SSLVPN_NativeApp_Settings.txt"}
Remove-Variable * -ErrorAction SilentlyContinue
$Error.Clear()