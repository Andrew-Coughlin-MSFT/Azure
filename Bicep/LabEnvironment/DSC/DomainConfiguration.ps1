param([string] $domainFQDN)


$domain=$domainFQDN
$domainDN = "DC=$($domain.replace(".", ",DC="))"

##Setup OUs for Domain
Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

Import-Module -Name ActiveDirectory

New-ADOrganizationalUnit -Name "All Users" -Path $domainDN -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Groups" -Path $domainDN -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Server Accounts" -Path $domainDN -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Servers" -Path $domainDN -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "W2K19" -Path "OU=All Servers,$domainDN" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "W2K22" -Path "OU=All Servers,$domainDN" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Desktops" -Path $domainDN -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Autopilot Domain Join" -Path "OU=All Desktops,$domainDN" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "AzureFiles" -Path $domainDN -ProtectedFromAccidentalDeletion $true
