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
param OSVersion string = '2022-datacenter-g2'

// @description('Domain to create.')
// param serverDomainName string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Enable automatic Windows Updates.')
param enableAutomaticUpdates bool = true

@description('Enable Azure Hybrid Benefit to use your on-premises Windows Server licenses and reduce cost. See https://docs.microsoft.com/en-us/azure/virtual-machines/windows/hybrid-use-benefit-licensing for more information.')
param enableHybridBenefitServerLicenses bool = true

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param vmdnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Storage Account Object to be used during the creation of the VM.')
param stg object

@description('SKU for the Public IP used to access the Virtual Machine.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

// @description('Organizational Unit path in which the nodes and cluster will be present.')
// param ouPath string

// @description('Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx')
// param domainJoinOptions int = 3

var vmnicName = toLower('${vmName}-vmnic01')
var vmsubnetName = 'jumpbox-sn'
var virtualNetworkName = 'vNet-LAB'
var shutdownSchedule = 'shutdown-computevm-${vmName}'
// var domainName = serverDomainName
var adPDCModulesURL ='https://github.com/Andrew-Coughlin-MSFT/Azure/blob/master/Bicep/LabEnvironment/DSC/InstallADDNSTools.zip?raw=true'
var adPDCConfigurationFunction = 'InstallADDNSTools.ps1\\InstallADDNSTools'

resource vmpip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name:'${vmName}-pip'
  location:location
  sku:{
    name:publicIpSku
  }
  properties:{
    publicIPAllocationMethod:'Dynamic'
    dnsSettings:{
      domainNameLabel:vmdnsLabelPrefix
    }
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

module vm_shutdownSchedule '../nestedtemplate/createShutdownSchedule.bicep' ={
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
// resource vm_shutdownResourceName 'Microsoft.DevTestLab/schedules@2018-09-15' = {
//   name: shutdownSchedule
//   location: location
//   properties: {
//     status: 'Enabled'
//     taskType: 'ComputeVmShutdownTask'
//     dailyRecurrence: {
//       time: '19:00'
//     }
//     timeZoneId: 'Central Standard Time'
//     notificationSettings: {
//       status: 'Disabled'
//       timeInMinutes: 30
//     }
//     targetResourceId: vm.id
//   }
// }

resource vmnic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: vmnicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress:{
            id:vmpip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, vmsubnetName)
          }
        }
      }
    ]
  }
}

resource vmInstallADDNS_Tools 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: vm
  name: 'InstallADDNSTools'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: adPDCModulesURL
      ConfigurationFunction: adPDCConfigurationFunction
    }
  }
}

module AzureIaasMalware '../nestedtemplate/DeployIaasAntimalware.bicep'={
  name:'DeployIaasMalware'
  params:{
    location:location
    scantype:'Quick'
    vm:vm.name
  }
  dependsOn:[
    vmInstallADDNS_Tools
  ]
}

// resource virtualMachineExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
//   parent: vm
//   name: 'joindomain'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Compute'
//     type: 'JsonADDomainExtension'
//     typeHandlerVersion: '1.3'
//     autoUpgradeMinorVersion: true
//     settings: {
//       name: domainName
//       ouPath: ouPath
//       user: '${domainName}\\${adminUsername}'
//       restart: true
//       options: domainJoinOptions
//     }
//     protectedSettings: {
//       Password: adminPassword
//     }
//   }
// }
