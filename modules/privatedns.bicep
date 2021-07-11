param location string = 'global'
param dnsZoneName string
param vnetName string
param tagValues object

var vnetLinkName = '${dnsZoneName}/${dnsZoneName}.link'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: location
  name: dnsZoneName
  tags: tagValues
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: vnetLinkName
  location: location
  tags: tagValues
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    } 
    registrationEnabled: true
  }
  dependsOn: [
    privateDnsZone
  ]

}
