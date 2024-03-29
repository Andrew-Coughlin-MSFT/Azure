# Azure
This project will create 3 servers on Windows Server 2022.  Domain Controller, Jumpbox, and AD Connect Server.  With the virtual networks, NSG, shutdown schedules.  Will join the member servers to the domain and preconfigure the domain with specific OUs.

# Prerequisites
In order to make sure this deployment is successful you need to register "EncryptionAtHost" feature, to do this follow these instructions per subscription you will be deploying to: https://docs.microsoft.com/en-us/azure/virtual-machines/disks-enable-host-based-encryption-portal#prerequisites

# Deployment
$rgname = "<rg-name>" <br/>
$location = "<azure region name>"<br/>
New-AzResourceGroup -Name $rgname -Location $location

New-AzResourceGroupDeployment -ResourceGroupName $rgname -TemplateFile <path-to-template>\DeployLabResources.bicep -adminUsername <username> -vmDCName <DCName> -serverDomainName <Domain.fqdn> -vmJumpboxName <JumpboxName> -vmADCName <ADConnectServerName>

# Disclaimer
The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.