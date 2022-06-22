
@description('Location for all resources.')
param location string = resourceGroup().location

var addressPrefix = '10.4.0.0/16'
var virtualNetworkName = 'vNet-LAB'
var networkSecurityGroupName = 'labresource-sn-NSG'

resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
  }
}

resource networkSecurityGroups_nsLabWorkstationSubnet_name_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsLabWorkstationSubnet'
  location: location
  properties: {
    securityRules: []
  }
}

resource networkSecurityGroups_nsgSQLsn01_name_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsgSQLsn01'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SecurityCenter-JITRule_-36095858_14C0018BC44A4D82B37173F30C4ECE26'
        properties: {
          description: 'ASC JIT Network Access rule for policy \'default\' of VM \'WFCI02\'.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.4.5'
          access: 'Deny'
          priority: 4096
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

resource networkSecurityGroups_LAB_vnet_AzureBastionSubnet_nsg_name_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'AzureBastionSubnet_nsg'
  location: location
  properties: {
    securityRules: []
  }
}

resource networkSecurityGroups_LAB_vnet_default_nsg_centralus_name_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'default_nsg'
  location: location
  properties: {
    securityRules: []
  }
}

resource networkSecurityGroups_nsLabJumpServerSubnet_name_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsLabJumpServerSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SecurityCenter-JITRule_-249273273_AD9CD0BDB51244CEBCF7865DC2D160BB'
        properties: {
          description: 'ASC JIT Network Access rule for policy \'default\' of VM \'ADJUMP02SRV\'.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.0.1.5'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'SecurityCenter-ANHRule_TCP_Inbound_DENY_1626259180214'
        properties: {
          description: 'ASC Adaptive Network Controls rule of VM \'ADJUMP01SRV\''
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.0.1.4'
          access: 'Deny'
          priority: 1001
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'SecurityCenter-ANHRule_UDP_Inbound_DENY_1626259180212'
        properties: {
          description: 'ASC Adaptive Network Controls rule of VM \'ADJUMP01SRV\''
          protocol: 'UDP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.0.1.4'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
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
    dhcpOptions: {
      dnsServers: [
        '10.0.0.4'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.3.0/27'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'centralus'
                'eastus2'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'workstation-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_nsLabWorkstationSubnet_name_resource
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'centralus'
                'eastus2'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'sql-sn01'
        properties: {
          addressPrefix: '10.0.4.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_nsgSQLsn01_name_resource.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'centralus'
                'eastus2'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.5.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_LAB_vnet_AzureBastionSubnet_nsg_name_resource.id
          }
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_LAB_vnet_default_nsg_centralus_name_resource.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'centralus'
                'eastus2'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'jumpserver-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroups_nsLabJumpServerSubnet_name_resource.id
          }
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'centralus'
                'eastus2'
              ]
            }
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}
