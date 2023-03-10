@description('The name of the Virtual Network to Create')
param virtualNetworkName string

@description('The address range of the new VNET in CIDR format')
param virtualNetworkAddressRange string

@description('Location for all resources.')
param location string

@allowed([
  'new'
  'existing'
])
param newOrExisting string = 'new'

resource nsgServerSn 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-server-sn'
  location: location
  properties: {
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = if (newOrExisting =='new'){
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressRange
      ]
    }
    subnets: [
      {
        name: 'server-sn'
        properties: {
          addressPrefix: '10.4.0.0/24'
          networkSecurityGroup: {
            id: nsgServerSn.id
          }
        }
      }
    ]
    
  }
}
