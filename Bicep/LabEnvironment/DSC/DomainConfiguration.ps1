param([string] $domainFQDN)

Configuration CreateDomainOUs
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration,ActiveDirectory

    Node localhost
    {
            $domain=$domainFQDN
            $domainDN = "DC=$($domain.replace(".", ",DC="))"
                      
            New-ADOrganizationalUnit -Name "All Users" -Path $domainDN -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "All Groups" -Path $domainDN -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "All Server Accounts" -Path $domainDN -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "All Servers" -Path $domainDN -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "W2K19" -Path "OU=All Servers,$domainDN" -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "W2K22" -Path "OU=All Servers,$domainDN" -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "All Desktops" -Path $domainDN -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "Autopilot Domain Join" -Path "OU=All Desktops,$domainDN" -ProtectedFromAccidentalDeletion $true
            New-ADOrganizationalUnit -Name "AzureFiles" -Path $domainDN -ProtectedFromAccidentalDeletion $true
    }
}
