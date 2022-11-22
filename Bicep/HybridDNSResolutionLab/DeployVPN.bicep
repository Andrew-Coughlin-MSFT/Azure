@description('Location for all resources.')
param location string = resourceGroup().location

param PublicIPAddressName string
param VirtualNetworkName string
param VirtualNetworkGWName string
param localnetworkgatewayname string
param connectionName string
param AddressPrefixes array

param vmdnsLabelPrefix string = toLower('${PublicIPAddressName}')
param publicIpSku string = 'Standard'


resource vmpip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name:'${PublicIPAddressName}-pip'
  location:location
  sku:{
    name:publicIpSku
  }
  properties:{
    publicIPAllocationMethod:'Dynamic'
    dnsSettings:{
      domainNameLabel:vmdnsLabelPrefix
    }
  }
}
module virtualNetworkGateway './nestedtemplate/VirtualNetworkGateway.bicep' = {
  name: 'VirtualNetworkGateway'
  params: {
    enableBGP: false
    gatewayType: 'Vpn'
    location: location
    PublicIpAddressName: vmpip.name
    rgName: location
    sku: 'VpnGw1'
    SubnetName: 'GatewaySubnet'
    virtualNetworkGatewayName: VirtualNetworkGWName
    VirtualNetworkName: VirtualNetworkName
    vpnType: 'RouteBased'
  }
}

module localNetworkGateway './nestedtemplate/CreateLocalNetworkGateway.bicep' = {
  name: 'LocalNetworkGateway'
  params: {
    addressPrefixes: [
      AddressPrefixes
    ]
    gatewayIpAddress: virtualNetworkGateway.outputs.publicip
    localNetworkGatewayName: localnetworkgatewayname
    location: location
  }
}

module connection './nestedtemplate/CreateConnection.bicep' = {
  name: 'connection'
  params: {
    connectionName: connectionName
    connectionType: 'IPSec'
    enableBgp: false
    localNetworkGatewayId: localNetworkGateway.outputs.lngid
    location: location
    sharedKey: 'dhsjkdlahldk23e2mda'
    virtualNetworkGatewayId: virtualNetworkGateway.outputs.vngid
  }
}
