@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Virtual Machine Name.')
@maxLength(15)
param vmName string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Enable automatic Windows Updates.')
param enableAutomaticUpdates bool = true

@description('Enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/hybrid-use-benefit-licensing for more information.')
param enableHybridBenefitServerLicenses bool = true

@description('The Windows version for the VM. This will pick a fully patched Gen2 image of this given Windows version.')
@allowed([
 '2019-datacenter-gensecond'
 '2019-datacenter-core-gensecond'
 '2019-datacenter-core-g2'
 '2019-datacenter-core-smalldisk-gensecond'
 '2016-datacenter-gensecond'
 '2016-datacenter-server-core-g2'
 '2022-datacenter-g2'
 '2022-datacenter-azure-edition-core'
])
param OSVersion string = '2019-datacenter-gensecond'

param vNetNewOrExisting string ='new'

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var addressPrefix = '10.1.0.0/16'
var virtualNetworkName = 'EastUS-vNET01'
var vmnicName = toLower('${vmName}-vmnic01')
var vmsubnetName = 'server-sn'
var shutdownSchedule = 'shutdown-computevm-${vmName}'

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

module vn './nestedtemplate/create-virtual-networks.bicep' ={
  name: 'CreateVirtualNetwork'
  params: {
    location:location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: addressPrefix
    newOrExisting:vNetNewOrExisting
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: enableAutomaticUpdates
        provisionVMAgent: true
        patchSettings: {
          patchMode: (enableAutomaticUpdates ? 'AutomaticByPlatform' : 'Manual')
          assessmentMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption:'Delete'
      }
    }
    securityProfile:{
      encryptionAtHost:true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmnic.id
          properties:{
            deleteOption:'Delete' 
           }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
    licenseType: (enableHybridBenefitServerLicenses ? 'Windows_Server' : json('null'))
  }
}

module vm_shutdownSchedule './nestedtemplate/create-shutdown-schedule.bicep' ={
  name: 'CreateShutdownSchedule'
  params:{
    location:location
    notificationSettingsStatus:'Disabled'
    shutdownScheduleName:shutdownSchedule
    shutdownStatus:'Enabled'
    shutdownTime:'19:00'
    timeZoneId:'Central Standard Time'
    vmid:vm.id
  }
}

resource vmnic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: vmnicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, vmsubnetName)
          }
        }
      }
    ]
  }
  dependsOn:[
    vn
  ]
}

module AzureIaasMalware './nestedtemplate/deploy-iaas-antimalware.bicep'={
  name:'DeployIaasMalware'
  params:{
    location:location
    scantype:'Quick'
    vm:vm.name
  }
}

module AzureMonitorAgent './nestedtemplate/deploy-azure-monitor-agent.bicep' ={
  name:'DeployAzureMonitorAgent'
  params:{
    location:location
    vmName:vm.name
  }
  dependsOn:[
    AzureIaasMalware
  ]
}
