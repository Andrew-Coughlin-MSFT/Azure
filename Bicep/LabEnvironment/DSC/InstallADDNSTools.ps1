configuration InstallADDNSTools
{
   param
   (
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
     Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
        }

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
        }

        WindowsFeature GPMC
        {
            Ensure = "Present"
            Name = "GPMC"
        }
        
        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name ="RSAT-AD-PowerShell"
        }
   }
}