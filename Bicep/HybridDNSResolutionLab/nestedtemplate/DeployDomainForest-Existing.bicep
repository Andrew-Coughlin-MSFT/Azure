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

@description('Storage Account Object to be used during the creation of the VM.')
param stg object

param vmsubnetName string
param virtualNetworkName string
param adBDCModulesConfigureURL string
param adBDCConfigureFunction string

var vmnicName = toLower('${vmName}-vmnic01')

var shutdownSchedule = 'shutdown-computevm-${vmName}'
var availabilitySetName = toLower('as${vmName}')
var domainName = serverDomainName


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
      dataDisks: [
        {
          diskSizeGB: 32
          lun: 0
          createOption: 'Empty'
          deleteOption:'Delete'
        }
      ]
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
    availabilitySet:{
      id:asvm.id
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

module vm_shutdownSchedule '../nestedtemplate/create-shutdown-schedule.bicep' ={
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
}

resource asvm 'Microsoft.Compute/availabilitySets@2021-11-01' = {
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

resource vmDCVMName_ConfigureBDC 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: vm
  name: 'ConfigureBDC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: adBDCModulesConfigureURL
      ConfigurationFunction: adBDCConfigureFunction
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
  dependsOn:[
    vmDCVMName_PrepareADBDC
  ]
}

module AzureIaasMalware '../nestedtemplate/deploy-iaas-antimalware.bicep'={
  name:'DeployIaasMalware'
  params:{
    location:location
    scantype:'Quick'
    vm:vm.name
  }
  dependsOn:[
    vmDCVMName_ConfigureBDC
  ]
}

module AzureMonitorAgent '../nestedtemplate/deploy-azure-monitor-agent.bicep' ={
  name:'DeployAzureMonitorAgent'
  params:{
    location:location
    vmName:vm.name
  }
  dependsOn:[
    AzureIaasMalware
  ]
}

