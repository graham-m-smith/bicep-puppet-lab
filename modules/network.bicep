param location string
param vnetName string
param vnetAddressPrefixes array
param subnetName string
param subnetAddressPrefix string
param nsgName string
param tagValues object

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  tags: tagValues
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', nsgName)
          }
        }
      }
    ]
  }
  


}

