param location string
param rulesList array
param tagValues object

resource asg 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = [for rule in rulesList: {
  name: rule.asgname
  location: location
  tags: tagValues
}]
