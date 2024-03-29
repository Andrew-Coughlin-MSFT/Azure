@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Virtual Machine Name for domain controller.')
@maxLength(15)
param vmDCName string

@description('Virtual Machine Name for jumpbox.')
@maxLength(15)
param vmJumpboxName string

@description('Domain to create.')
param serverDomainName string

 @description('Organizational Unit path in which the nodes and cluster will be present.')
param ouPath string ='OU=W2K22,OU=All Servers,DC=LAB,DC=LOCAL'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var HubEastaddressPrefix = '10.10.0.0/16'
var HubEastvirtualNetworkName = 'vNet-East-Hub1'
var vmDCPrivateIPAddress = '10.41.0.5'
var domainName = serverDomainName
var vmsubnetName = 'server-sn'

var adPDCModulesURL ='https://github.com/Andrew-Coughlin-MSFT/Azure/blob/master/Bicep/HybridDNSResolutionLab/DSC/CreateADPDC.zip?raw=true'
var adPDCConfigurationFunction = 'CreateDomainControllerExisting.zip\\CreateADPDC'


resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties:{
    minimumTlsVersion:'TLS1_2'

    networkAcls:{
      defaultAction:'Deny'
      bypass:'AzureServices'
    }
  }
}
module UpdateVNetDNS './nestedtemplate/update-vnet-dns-settings-azure-east.bicep' = {
  name: 'UpdateVNetDNS'
  params: {
    virtualNetworkName: HubEastvirtualNetworkName
    virtualNetworkAddressRange: HubEastaddressPrefix
    DNSServerAddress: [
      vmDCPrivateIPAddress
    ]
    location: location
  }
  dependsOn: [
    domaincontroller
  ]
}
module vn './nestedtemplate/create-virtual-networks-azure-east.bicep' ={
  name: 'CreateVirtualNetworkAzureEast'
  params: {
    location:location
    virtualNetworkName: HubEastvirtualNetworkName
    virtualNetworkAddressRange: HubEastaddressPrefix
    vmName:vmDCName
  }
}
module vnspoke './nestedtemplate/create-virtual-networks-east-spoke.bicep' ={
  name: 'CreateVirtualSpokeNetworkAzureEast'
  params: {
    location:location
    virtualNetworkName: HubEastvirtualNetworkName
    virtualNetworkAddressRange: HubEastaddressPrefix
  }
}
module domaincontroller './nestedtemplate/DeployDomainForest.bicep'={
  name:'CreateDomainController'
  params:{
    location:location
    adminPassword:adminPassword
    adminUsername:adminUsername
    vmName:vmDCName
    stg:stg
    vmSize:vmSize
    serverDomainName:domainName
    virtualNetworkName:HubEastvirtualNetworkName
    vmsubnetName:vmsubnetName
    adPDCConfigurationFunction: adPDCConfigurationFunction
    adPDCModulesURL: adPDCModulesURL
  }
  dependsOn:[
    vn 
   ]
}

// resource resourceGroupLock 'Microsoft.Authorization/locks@2017-04-01'={
//   name:'resourceLock'
//   scope: resourceGroup()
//   properties:{
//     level:'CanNotDelete'
//     notes:'Resource group and its resources should not be deleted.'
//   }
//   dependsOn:[
//     adconnectserver
//   ]
// }


