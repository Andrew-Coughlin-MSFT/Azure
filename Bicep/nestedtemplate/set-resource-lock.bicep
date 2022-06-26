@description('The name of the Virtual Network to Create')
param resourceGroupLockName string

resource createRgLock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: resourceGroupLockName
  properties: {
    level: 'CanNotDelete'
    notes: 'Resource group should not be deleted.'
  }
}
