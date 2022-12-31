param project string
param vnetAddressPrefixes array
param subnetAddressPrefix string
param location string = resourceGroup().location
param tag_values object

param local_tags object = {
  LastDeploy: utcNow('d')
} 

// Append LastDeploy tag to tag_values from parameter file
var all_tags = union(tag_values, local_tags)

var vnetName = 'vnet-${project}'
var subnetName = 'subnet-${project}'
var nsgName = 'nsg-${subnetName}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  tags: all_tags
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

