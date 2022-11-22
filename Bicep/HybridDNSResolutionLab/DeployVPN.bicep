@description('Location for all resources.')
param location string = resourceGroup().location

param PublicIPAddressName string
param VirtualNetworkName string
param VirtualNetworkGWName string

module virtualNetworkGateway './nestedtemplate//VirtualNetworkGateway.bicep' = {
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
