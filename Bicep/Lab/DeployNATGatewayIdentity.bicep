param location string = resourceGroup().location
param ngname string = 'nnidentity001'

module natGateway 'br/public:avm/res/network/nat-gateway:1.0.5' = {
  name: 'natGatewayDeployment'
  params: {
    // Required parameters
    name: 'nnidentity001'
    zone: 0 // Non-required parameters
    location: location
    tags: {
      Division: 'Core'
      Environment: 'Hybrid'
      Purpose: 'UserTenant'
      Backup: 'False'
    }
    publicIPAddressObjects: [
      {
        name: '${ngname}-pip'
      }
    ]
    
  } 

}
