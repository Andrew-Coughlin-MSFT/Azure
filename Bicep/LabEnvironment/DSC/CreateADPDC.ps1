configuration CreateADPDC 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where-Object Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)
    #Convert FQDN to Distinguished Name
    $DN = 'CN=' + $DomainName.Replace('.',',CN=')

    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        Script EnableDNSDiags
	    {
      	    SetScript = { 
		        Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript =  { @{} }
            TestScript = { $false }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk {
            DiskNumber = 2
            DriveLetter = "F"
            DependsOn = "[xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
	        DependsOn="[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
	        DependsOn = @("[xDisk]ADDataDisk", "[WindowsFeature]ADDSInstall")
        } 

        xADOrganizationalUnit AllUsersOU
        {
            Name ="All Users"
            Path = $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllGroupsOU
        {
            Name = "All Groups"
            Path = $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllServiceAccountsOU
        {
            Name = "All Service Accounts"
            Path = $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllServersOU
        {
            Name = "All Servers"
            Path = $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllDesktopsOU
        {
            Name = "All Desktops"
            Path = $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AzureFilesOU
        {
            Name = "AzureFiles"
            Path = $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllServersW2K19OU
        {
            Name = "W2K19"
            Path = 'OU=All Servers,' + $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADOrganizationalUnit]AllServersOU"
        }
        xADOrganizationalUnit AllServersW2K22OU
        {
            Name = "W2K22"
            Path = 'OU=All Servers,' + $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADOrganizationalUnit]AllServersOU"
        }
        xADOrganizationalUnit AllServersAutoPilotDomainJoinOU
        {
            Name = "Autopilot Domain Join"
            Path = 'OU=All Desktops,' + $DN
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADOrganizationalUnit]AllDesktopsOU"
        }
   }
} 