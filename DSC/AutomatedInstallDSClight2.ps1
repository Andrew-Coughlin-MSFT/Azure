configuration AutomatedInstallDSClight
{
    node localhost
    {
        File AutomatedInstall-01-22-2021
        {
            Ensure = "Present"
            Type = "Directory"
            Recurse = $true
            SourcePath = "\\addc01\DSC_Share\RequiredSoftware\CyberSecurity"
            DestinationPath = "C:\CyberSecurityDSC\Tools"
            MatchSource = $true
            Checksum = "SHA-256"
            Force = $true
        }
        # Use this to find the ProductId: Get-CimInstance -ClassName Win32_Product | Sort Vendor, Name| Select Vendor, Name, IdentifyingNumber
        Package AdobeReaderDC-06-25-2018
        {
            Ensure = "Present"
            Name = 'Adobe Reader DC'
            Path = 'C:\CyberSecurityDSC\Tools\AdobeReader\AcroRdrDC2001320074_en_US.exe'
            ProductId = ''
            Dependson = @("[file]AutomatedInstall-01-22-2021")
        }
        Package MicrosoftEdge-10-30-2020
        {
            Ensure = "Present"
            Name = 'Microsoft Edge'
            Path = 'C:\CyberSecurityDSC\Tools\Edge\MicrosoftEdgeEnterpriseX64.msi'
            ProductId = 'C8ABBB68-32C7-3004-A4CA-6CD0A0B815D4'
            Dependson = @("[file]AutomatedInstall-01-22-2021")
        }
        Package RemoteDesktop-12-04-2020
        {
            Ensure = "Present"
            Name = 'Remote Desktop'
            Path = 'C:\CyberSecurityDSC\Tools\RemoteDesktop\RemoteDesktop_1.2.1446.0_x64.msi'
            ProductId = '3C293135-ABB8-4685-BE36-044EC98DC753'
            Dependson = @("[file]AutomatedInstall-01-22-2021")
        }
        File TestDscCompliance
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = "C:\TestDscCompliance"
        }
        Log AfterDirectoryCopy
        {
            # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
            Message = "Finished running the file resource with ID FileCopy"
            DependsOn = @("[file]AutomatedInstall-01-22-2021","[Package]AdobeReaderDC-06-25-2018","[Package]MicrosoftEdge-10-30-2020","[Package]RemoteDesktop-12-04-2020","[file]AutomatedInstall-01-22-2021")
        }
    }
} 