@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Virtual Machine Name.')
@maxLength(15)
param vmName string

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
var nicName = toLower('${vmName}-vmnic01')
var addressPrefix = '10.4.0.0/16'
var subnetName = 'server-sn'
var subnetPrefix = '10.4.0.0/24'
var virtualNetworkName = 'vNet-LAB'
var networkSecurityGroupName = 'nsg-server-sn'
var dcPrivateIPAddress = '10.4.0.4'
var availabilitySetName = toLower('as${vmName}')
var shutdownScheduleName = 'shutdown-computevm-${vmName}'
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

resource as 'Microsoft.Compute/availabilitySets@2021-11-01' = {
  name:availabilitySetName
  location: location
  properties:{
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 3
  }
  sku:{
    name:'Aligned'
  }
}

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
  }
}

resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: securityGroup.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress:dcPrivateIPAddress
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn.name, subnetName)
          }
        }
      }
    ]
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
          id: nic.id
        }
      ]
    }
    availabilitySet:{
      id:as.id
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
  name: shutdownScheduleName
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
    targetResourceId: vm.id
  }
}

resource adPDCVMName_CreateADForest 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: vm
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
        AdminPassword: 'Password123456!'
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
      dcPrivateIPAddress
    ]
    location: location
  }
  dependsOn: [
    adPDCVMName_CreateADForest
  ]
}

resource resourceGroupLock 'Microsoft.Authorization/locks@2017-04-01'={
  name:'resourceLock'
  scope: resourceGroup()
  properties:{
    level:'CanNotDelete'
    notes:'Resource group and its resources should not be deleted.'
  }
}

output hostname string = vm.name

