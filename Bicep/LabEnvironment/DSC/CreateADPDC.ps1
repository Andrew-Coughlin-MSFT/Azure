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
            Path = "DC=lab,DC=local"
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllGroupsOU
        {
            Name = "All Groups"
            Path = "DC=lab,DC=local"
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllServiceAccountsOU
        {
            Name = "All Service Accounts"
            Path = "DC=lab,DC=local"
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllServersOU
        {
            Name = "All Servers"
            Path = "DC=lab,DC=local"
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllDesktopsOU
        {
            Name = "All Desktops"
            Path = "DC=lab,DC=local"
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADDomain]FirstDS"
        }
        xADOrganizationalUnit AllServersW2K19OU
        {
            Name = "W2K19"
            Path = "OU=All Servers,DC=lab,DC=local"
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADOrganizationalUnit]AllServersOU"
        }
        xADOrganizationalUnit AllServersW2K22OU
        {
            Name = "W2K22"
            Path = "OU=All Servers,DC=lab,DC=local"
            ProtectedFromAccidentalDeletion = $true
            DependsOn = "[xADOrganizationalUnit]AllServersOU"
        }

        # Script CreateADOUs
	    # {
        #     SetScript = {
        #         Write-Verbose -Verbose $DomainName 
        #         $domain=$DomainName
        #         $domainDN = "DC=$($domain.replace(".", ",DC="))"
        #         Write-Verbose -Verbose $domainDN  
                
        #         New-ADOrganizationalUnit -Name "All Users" -Path $domainDN -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "All Groups" -Path $domainDN -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "All Server Accounts" -Path $domainDN -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "All Servers" -Path $domainDN -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "W2K19" -Path "OU=All Servers,$domainDN" -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "W2K22" -Path "OU=All Servers,$domainDN" -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "All Desktops" -Path $domainDN -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "Autopilot Domain Join" -Path "OU=All Desktops,$domainDN" -ProtectedFromAccidentalDeletion $true
        #         New-ADOrganizationalUnit -Name "AzureFiles" -Path $domainDN -ProtectedFromAccidentalDeletion $true
        #     }
        #     GetScript =  { @{} }
        #     TestScript = { $false }
	    #     DependsOn = "[xADDomain]FirstDS"
        # }

   }
} 