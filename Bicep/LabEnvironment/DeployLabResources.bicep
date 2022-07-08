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

@description('Virtual Machine Name for ad connect.')
@maxLength(15)
param vmADCName string

@description('Domain to create.')
param serverDomainName string

 @description('Organizational Unit path in which the nodes and cluster will be present.')
param ouPath string ='OU=W2K22,OU=All Servers,DC=LAB,DC=LOCAL'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var addressPrefix = '10.4.0.0/16'
var virtualNetworkName = 'vNet-LAB'
var vmDCPrivateIPAddress = '10.4.0.4'
var domainName = serverDomainName

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
module UpdateVNetDNS './nestedtemplate/update-vnet-dns-settings.bicep' = {
  name: 'UpdateVNetDNS'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: addressPrefix
    DNSServerAddress: [
      vmDCPrivateIPAddress
    ]
    location: location
  }
  dependsOn: [
    domaincontroller
  ]
}
module vn './nestedtemplate/create-virtual-networks.bicep' ={
  name: 'CreateVirtualNetwork'
  params: {
    location:location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: addressPrefix
    vmName:vmDCName
  }
}
module jumpboxvm './nestedtemplate/DeployJumpboxServer.bicep'={
  name:'CreateJumpboxVM'
  params:{
    location:location
    adminPassword:adminPassword
    adminUsername:adminUsername
    vmName:vmJumpboxName
    vmSize:vmSize
    stg:stg
    ouPath:ouPath
    serverDomainName:serverDomainName
  }
  dependsOn:[
   vn 
   domaincontroller
   UpdateVNetDNS
  ]
}

module domaincontroller './nestedtemplate/DeployDomainForest.bicep'={
  name:'CreateDomainControllerForest'
  params:{
    location:location
    adminPassword:adminPassword
    adminUsername:adminUsername
    vmName:vmDCName
    stg:stg
    vmSize:vmSize
    serverDomainName:domainName
  }
  dependsOn:[
    vn 
   ]
}

module adconnectserver 'nestedtemplate/DeployADConnectServer.bicep'={
  name:'CreateADConnectServer'
  params:{
    location:location
    adminPassword:adminPassword
    adminUsername:adminUsername
    stg:stg
    vmName:vmADCName
    vmSize:vmSize
    ouPath:ouPath
    serverDomainName:serverDomainName
  }
  dependsOn:[
    vn 
    domaincontroller
    UpdateVNetDNS
   ]
}

// resource resourceGroupLock 'Microsoft.Authorization/locks@2017-04-01'={
//   name:'resourceLock'
//   scope: resourceGroup()
//   properties:{
//     level:'CanNotDelete'
//     notes:'Resource group and its resources should not be deleted.'
//   }
// }


