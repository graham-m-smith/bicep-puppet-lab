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
/*
{"error":{"code":"InvalidTemplate","message":"Deployment template validation failed: 'The template resource '[parameters('rulesList')[copyIndex()].asgname]' at line '1' and column '1834' is not valid: The language expression property 'asgname' doesn't exist, available properties are 'name, priority, description, direction, access, protocol, sourceAddressPrefixes, sourcePortRange, destinationPortRange'.. Please see https://aka.ms/arm-template-expressions for usage details.'.","additionalInfo":[{"type":"TemplateViolation","info":{"lineNumber":1,"linePosition":1834,"path":"properties.template.resources[0]"}}]}}
*/
