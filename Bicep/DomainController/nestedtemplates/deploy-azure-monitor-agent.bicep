@description('Location for all resources.')
param location string

@description('Virtual Machine Name.')
@maxLength(15)
param vmName string

resource windowsAgent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: '${vmName}/AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}
