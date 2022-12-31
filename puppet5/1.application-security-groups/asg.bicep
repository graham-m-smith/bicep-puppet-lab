param asg_list array
param location string = resourceGroup().location
param tag_values object

param local_tags object = {
  LastDeploy: utcNow('d')
} 

// Append LastDeploy tag to tag_values from parameter file
var all_tags = union(tag_values, local_tags)

resource asg 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = [for asg_name in asg_list: {
  name: asg_name
  location: location
  tags: all_tags
}]
