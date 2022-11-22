@description('Location for all resources.')
param location string = resourceGroup().location

param PublicIPAddressName string
param VirtualNetworkName string
param VirtualNetworkGWName string
param localnetworkgatewayname string
param connectionName string
param AddressPrefixes array

module virtualNetworkGateway './nestedtemplate/VirtualNetworkGateway.bicep' = {
  name: 'VirtualNetworkGateway'
  params: {
    enableBGP: false
    gatewayType: 'Vpn'
    location: location
    PublicIpAddressName: PublicIPAddressName
    rgName: resourceGroup().name 
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
