param project string
param dnsZoneName string
param dnsCNAMEList array
param location string = 'global'
param tag_values object

param local_tags object = {
  LastDeploy: utcNow('d')
} 

// Append LastDeploy tag to tag_values from parameter file
var all_tags = union(tag_values, local_tags)

var vnetName = 'vnet-${project}'
var vnetLinkName = '${dnsZoneName}/${dnsZoneName}.link'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: location
  name: dnsZoneName
  tags: all_tags
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: vnetLinkName
  location: location
  tags: all_tags
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

resource cname 'Microsoft.Network/privateDnsZones/CNAME@2020-06-01' = [for item in dnsCNAMEList: {
  name: '${dnsZoneName}/${item.cname}'
  properties: {
    ttl: item.ttl
    cnameRecord: {
      cname: '${item.target}.${dnsZoneName}'
    }
  }
  dependsOn: [
    privateDnsZone
    privateDnsZoneVnetLink
  ]
}]
