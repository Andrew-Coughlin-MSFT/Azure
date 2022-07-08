@description('Location for all resources.')
param location string

param domainFQDN string

param utcValue string = utcNow()

var adPDCModulesURL ='https://github.com/Andrew-Coughlin-MSFT/Azure/blob/master/Bicep/LabEnvironment/DSC/DomainConfiguration.ps1?raw=true'

resource DomainOUConfiguration 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ConfigureDomainOUs'
  location: location
  kind: 'AzurePowerShell'
  properties: {
    forceUpdateTag: utcValue
    timeout: 'PT1H'
    cleanupPreference: 'Always'
    azPowerShellVersion: '6.4'
    arguments:domainFQDN
    primaryScriptUri: adPDCModulesURL
    retentionInterval: 'P1D'
  }
}

output result string = DomainOUConfiguration.properties.outputs.text
