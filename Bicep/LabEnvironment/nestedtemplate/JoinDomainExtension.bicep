@description('Location for all resources.')
param location string

@description('Domain to join machine, should be FQDN')
param domainName string

@description('Organizational Unit path in which the nodes and cluster will be present.')
param ouPath string

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Set of bit flags that define the join options. Default value of 3 is a combination of NETSETUP_JOIN_DOMAIN (0x00000001) & NETSETUP_ACCT_CREATE (0x00000002) i.e. will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx')
@allowed([
  3
])
param domainJoinOptions int

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string


resource virtualMachineExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainName
      ouPath: ouPath
      user: '${domainName}\\${adminUsername}'
      restart: true
      options: domainJoinOptions
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
}
