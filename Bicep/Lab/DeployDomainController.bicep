param location string = resourceGroup().location
param rgname string = resourceGroup().name
param servername string ='AZDC01'

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.4.2' = {
  name: 'publicIpAddressDeployment'
  params: {
    // Required parameters
    name: 'lb-${servername}-publicip'
    // Non-required parameters
    location: location
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.5.3' = {
  name: 'virtualMachineDeployment'
  params: {
    zone:0
    // Required parameters
    adminUsername: 'azadmin'
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter'
      version: 'latest'
    }
    name: servername
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        ipConfigurations: [
          {
            deleteOption: 'Delete'
            name: 'ipconfig01'
            subnetResourceId: '/subscriptions/e1d7dfca-26ef-444b-8a30-4adba8296c53/resourceGroups/rg-identity-alz/providers/Microsoft.Network/virtualNetworks/vnet-Identity-ALZ/subnets/sn-domain-controllers'
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      createOption: 'FromImage'
      deleteOption: 'Delete'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS2_v2'
    // Non-required parameters
    adminPassword: 'password123456!'
    bypassPlatformSafetyChecksOnUserSchedule: true
    computerName: servername
    dataDisks: [
      {
        caching: 'ReadOnly'
        createOption: 'Empty'
        deleteOption: 'Delete'
        diskSizeGB: 32
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    ]
    enableAutomaticUpdates: true
    encryptionAtHost: true
    extensionAntiMalwareConfig: {
      enabled: true
      settings: {
        AntimalwareEnabled: 'true'
        Exclusions: {
          Extensions: '.ext1;.ext2'
          Paths: 'c:\\excluded-path-1;c:\\excluded-path-2'
          Processes: 'excludedproc1.exe;excludedproc2.exe'
        }
        RealtimeProtectionEnabled: 'true'
        ScheduledScanSettings: {
          day: '7'
          isEnabled: 'true'
          scanType: 'Quick'
          time: '120'
        }
      }
      tags: {
        Division: 'Core'
        Environment: 'Hybrid'
        Purpose: 'UserTenant'
        Backup: 'False'
      }
    }
    extensionDependencyAgentConfig: {
      enableAMA: true
      enabled: true
      tags: {
        Division: 'Core'
        Environment: 'Hybrid'
        Purpose: 'UserTenant'
        Backup: 'False'
      }
    }
    extensionDSCConfig: {
      enabled: true
      tags: {
        Division: 'Core'
        Environment: 'Hybrid'
        Purpose: 'UserTenant'
        Backup: 'False'
      }
    }
    extensionMonitoringAgentConfig: {
      enabled: true
      tags: {
        Division: 'Core'
        Environment: 'Hybrid'
        Purpose: 'UserTenant'
        Backup: 'False'
      }
    }
    extensionNetworkWatcherAgentConfig: {
      enabled: true
      tags: {
        Division: 'Core'
        Environment: 'Hybrid'
        Purpose: 'UserTenant'
        Backup: 'False'
      }
    }
    location: location
    patchMode: 'AutomaticByPlatform'
    licenseType: 'Windows_Server'
    tags: {
      Division: 'Core'
      Environment: 'Hybrid'
      Purpose: 'UserTenant'
      Backup: 'False'
    }
  }
}
resource AutoShutdownConfig 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'AutoShutdownConfig'
  location: location
  properties: {
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '18:00'
    }
    status: 'Enabled'
    timeZoneId: 'Central Standard Time'
    targetResourceId:virtualMachine.outputs.resourceId
  }
}

module loadBalancer 'br/public:avm/res/network/load-balancer:0.2.2' = {
  name: 'loadBalancerDeployment'
  params: {
    // Required parameters
    frontendIPConfigurations: [
      {
        name: 'publicIPConfig1'
        publicIPAddressId: publicIpAddress.outputs.resourceId
      }
    ]
    name: 'lb-${servername}'
    // Non-required parameters
    backendAddressPools: [
      {
        name: 'lb-${servername}-backendpool01'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: '${rgname}_${servername}-nic-01ipconfig01'
              properties: {}
            }
          ]
        }

      }
    ]
    inboundNatRules: [
      {
        backendPort: 3389
        enableFloatingIP: false
        enableTcpReset: false
        frontendIPConfigurationName: 'publicIPConfig1'
        frontendPort: 3389
        idleTimeoutInMinutes: 4
        name: 'lb-${servername}'
        targetvirtualMachineId: virtualMachine.outputs.name
        protocol: 'Tcp'
      }
    ]
    location: location
    tags: {
      Division: 'Core'
      Environment: 'Hybrid'
      Purpose: 'UserTenant'
      Backup: 'False'
    }
  }
}
