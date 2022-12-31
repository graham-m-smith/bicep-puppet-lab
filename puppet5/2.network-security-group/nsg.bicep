param project string
param rules_list array
param sourceAddressPrefixes string
param location string = resourceGroup().location
param tag_values object

param local_tags object = {
  LastDeploy: utcNow('d')
} 

// Append LastDeploy tag to tag_values from parameter file
var all_tags = union(tag_values, local_tags)

var subnetName = 'subnet-${project}'
var nsgName = 'nsg-${subnetName}'

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  tags: all_tags
  properties: {
    securityRules: [for rule in rules_list: {
      name: rule.asgname
      properties: {
        priority: rule.priority
        description: rule.description
        direction: rule.direction
        access: rule.access
        protocol: rule.protocol
        sourceAddressPrefixes: [ 
          sourceAddressPrefixes 
        ]
        sourcePortRange: rule.sourcePortRange
        destinationPortRange: rule.destinationPortRange
        destinationApplicationSecurityGroups: [
          {
            id: resourceId('Microsoft.Network/applicationSecurityGroups', rule.asgname)
          }
        ]
      }
    }]
  }
}
