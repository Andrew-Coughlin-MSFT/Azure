##Setup OUs for Domain
Install-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

Import-Module -Name ActiveDirectory

New-ADOrganizationalUnit -Name "All Users" -Path "DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Groups" -Path "DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Server Accounts" -Path "DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Servers" -Path "DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "W2K19" -Path "OU=All Servers,DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "W2K22" -Path "OU=All Servers,DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "All Desktops" -Path "DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Autopilot Domain Join" -Path "OU=All Desktops,DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "AzureFiles" -Path "DC=LAB,DC=LOCAL" -ProtectedFromAccidentalDeletion $true
