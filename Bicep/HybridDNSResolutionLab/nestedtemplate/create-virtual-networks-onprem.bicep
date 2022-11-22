@description('The name of the Virtual Network to Create')
param virtualNetworkName string

@description('The address range of the new VNET in CIDR format')
param virtualNetworkAddressRange string

@description('Location for all resources.')
param location string

@description('Virtual Machine Name.')
param vmName string

resource nsgServerSn  'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-server-sn'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Block All rdp access to VM'
        properties: {
          description: 'ASC JIT Network Access rule for policy \'default\' of VM \'${vmName}\'.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = {
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
          addressPrefix: '10.10.5.0/24'
          networkSecurityGroup: {
            id: nsgServerSn.id
          }
        }
      }
      {
        name:'GatewaySubnet'
        properties:{
          addressPrefix:'10.10.2.0/24'
          networkSecurityGroup: {
            id: nsgJumpboxSn.id
          }
        }
      }
    ]
    
  }
}
