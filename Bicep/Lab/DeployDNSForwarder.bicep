param location string = resourceGroup().location
param servername string ='DNS01'
param domainToJoin string = 'contoso.local'
param domainUsername string = 'azadmin'
param ouPath string = 'OU=Servers,OU=CONTOSO,DC=contoso,DC=local'
param domainJoinOptions int = 3
@description('Password of the account on the domain')
@secure()
param domainPassword string


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
  dependsOn: [
    virtualMachine
  ]
}

resource virtualMachineExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: '${servername}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: '${domainToJoin}\\${domainUsername}'
      restart: true
      options: domainJoinOptions
    }
    protectedSettings: {
      Password: domainPassword
    }
  }
  dependsOn: [
    virtualMachine
  ]
}

resource vmDNSEnabled 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  name: '${servername}/vm-EnableDNS-Script'
  location: location
  properties: {
    asyncExecution: false
    source: {
      script: '''
        Install-WindowsFeature -Name DNS -IncludeManagementTools
        $Forwarders = "168.63.129.16"
	      Set-DnsServerForwarder -IPAddress $Forwarders
      '''
    }
  }
  dependsOn: [
    virtualMachine
  ]
}
