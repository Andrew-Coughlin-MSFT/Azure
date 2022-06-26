@description('The name of the Virtual Network to Create')
param virtualNetworkName string

@description('The address range of the new VNET in CIDR format')
param virtualNetworkAddressRange string

@description('The DNS address(es) of the DNS Server(s) used by the VNET')
param DNSServerAddress array

@description('Location for all resources.')
param location string

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressRange
      ]
    }
    dhcpOptions: {
      dnsServers: DNSServerAddress
    }
  }
}
