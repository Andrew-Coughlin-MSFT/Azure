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
 '2019-datacenter-core-smalldisk-gensecond'
 '2019-datacenter-core-with-containers-gensecond'
 '2019-datacenter-core-with-containers-smalldisk-g2'
 '2019-datacenter-smalldisk-gensecond'
 '2019-datacenter-with-containers-gensecond'
 '2019-datacenter-with-containers-smalldisk-g2'
 '2016-datacenter-gensecond'
 '2022-datacenter-g2'
])
param OSVersion string = '2022-datacenter-g2'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('FQDN of the AD forest to create.')
@minLength(5)
param domainFQDN string = 'contoso.local'

@description('Enable automatic Windows Updates.')
param enableAutomaticUpdates bool = true

@description('Enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/hybrid-use-benefit-licensing for more information.')
param enableHybridBenefitServerLicenses bool = false

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation. When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = toLower('${vmName}-vmnic01')
var addressPrefix = '10.4.0.0/16'
var subnetName = 'labresource-sn'
var subnetPrefix = '10.4.0.0/24'
var virtualNetworkName = 'vNet-AVD'
var networkSecurityGroupName = 'labresource-sn-NSG'
var dcPrivateIPAddress = '10.4.0.4'
var availabilitySetName = toLower('as${vmName}')
var shutdownScheduleName = 'shutdown-computevm-labdc01'

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
          patchMode: (enableAutomaticUpdates ? 'AutomaticByOS' : 'Manual')
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
resource vmName_dscextension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01'= {
  parent:vm
  name:'CreateADForest'
  location:location
  properties:{
    publisher:'Microsoft.Powershell'
    type:'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: '3'
    settings: {
      //ModulesUrl: uri(artifactsLocation, 'DSC/CreateADPDC.zip${artifactsLocationSasToken}')
      url: 'https://saancoughlt01.blob.core.windows.net/dsc/CreateADPDC.zip'
      script: 'CreateADPDC.ps1'
      function: 'CreateADPDC'
      Properties: {
        DomainName: domainFQDN
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
// resource generalSettings_vmDCName_ConfigureDCVM 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
//   name: '${vmName}/ConfigureDCVM'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Powershell'
//     type: 'DSC'
//     typeHandlerVersion: '2.9'
//     autoUpgradeMinorVersion: true
//     forceUpdateTag: dscConfigureDCVM.forceUpdateTag
//     settings: {
//       wmfVersion: 'latest'
//       configuration: {
//         url: dscConfigureDCVM.scriptFileUri
//         script: dscConfigureDCVM.script
//         function: dscConfigureDCVM.function
//       }
//       configurationArguments: {
//         domainFQDN: domainFQDN
//         PrivateIP: dcPrivateIPAddress
//       }
//       privacy: {
//         dataCollection: 'enable'
//       }
//     }
//     protectedSettings: {
//       configurationArguments: {
//         AdminCreds: {
//           UserName: adminUsername
//           Password: adminPassword
//         }
//         AdfsSvcCreds: {
//           UserName: adminUsername
//           Password: adminPassword
//         }
//       }
//     }
//   }
//   dependsOn: [
//     vm
//   ]
  
// }
output hostname string = vm.name


