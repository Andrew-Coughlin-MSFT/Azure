@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Virtual Machine Name.')
@maxLength(15)
param vmDCName string

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
param OSVersion string = '2022-datacenter-azure-edition-core'

@description('Domain to create.')
param serverDomainName string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Enable automatic Windows Updates.')
param enableAutomaticUpdates bool = true

@description('Enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/hybrid-use-benefit-licensing for more information.')
param enableHybridBenefitServerLicenses bool = true

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var vmDCnicName = toLower('${vmDCName}-vmnic01')
var addressPrefix = '10.4.0.0/16'
var subnetName = 'server-sn'
var subnetPrefix = '10.4.0.0/24'
var virtualNetworkName = 'vNet-LAB'
var vmDCPrivateIPAddress = '10.4.0.4'
var availabilitySetVMDCName = toLower('as${vmDCName}')
var shutdownSchedulevmDCName = 'shutdown-computevm-${vmDCName}'
var domainName = serverDomainName
var adPDCModulesURL ='https://github.com/Andrew-Coughlin-MSFT/Azure/blob/master/Bicep/DSC/CreateADPDC.zip?raw=true'
var adPDCConfigurationFunction = 'CreateADPDC.ps1\\CreateADPDC'

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource asvmDC 'Microsoft.Compute/availabilitySets@2021-11-01' = {
  name:availabilitySetVMDCName
  location: location
  properties:{
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 3
  }
  sku:{
    name:'Aligned'
  }
}

resource vmDCnic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: vmDCnicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress:vmDCPrivateIPAddress
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn:[
    vn
  ]
}

resource vmDC 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmDCName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmDCName
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
      }
      dataDisks: [
        {
          diskSizeGB: 32
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmDCnic.id
        }
      ]
    }
    availabilitySet:{
      id:asvmDC.id
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

resource vmDC_shutdownResourceName 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: shutdownSchedulevmDCName
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '19:00'
    }
    timeZoneId: 'Central Standard Time'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
    targetResourceId: vmDC.id
  }
}

resource vmDCVMName_CreateADForest 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: vmDC
  name: 'CreateADForest'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: adPDCModulesURL
      ConfigurationFunction: adPDCConfigurationFunction
      Properties: {
        DomainName: domainName
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
}

module UpdateVNetDNS './nestedtemplate/update-vnet-dns-settings.bicep' = {
  name: 'UpdateVNetDNS'
  params: {
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: addressPrefix
    subnetName: subnetName
    subnetRange: subnetPrefix
    DNSServerAddress: [
      vmDCPrivateIPAddress
    ]
    location: location
  }
  dependsOn: [
    vmDCVMName_CreateADForest
  ]
}

module vn 'nestedtemplate/create-virtual-networks.bicep' ={
  name: 'CreateVirtualNetwork'
  params: {
    location:location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: addressPrefix
    vmName:vmDCName
  }
}

resource resourceGroupLock 'Microsoft.Authorization/locks@2017-04-01'={
  name:'resourceLock'
  scope: resourceGroup()
  properties:{
    level:'CanNotDelete'
    notes:'Resource group and its resources should not be deleted.'
  }
}

output hostname string = vmDC.name


