configuration InstallADDNSTools
{
   param
   (
        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

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
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature GPMC
        {
            Ensure = "Present"
            Name = "RSAT-GroupPolicy-Management-Tools"
        }
   }
}