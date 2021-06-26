param location string
param rulesList array
param nsgName string

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [for rule in rulesList: {
      name: rule.asgname
      properties: {
        priority: rule.priority
        description: rule.description
        direction: rule.direction
        access: rule.access
        protocol: rule.protocol
        sourceAddressPrefixes: [ 
          rule.sourceAddressPrefixes 
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
