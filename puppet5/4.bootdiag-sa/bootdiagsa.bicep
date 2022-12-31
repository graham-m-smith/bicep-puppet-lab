param project string
param bdStorageAccountSku string
param bdStorageAccountKind string
param location string = resourceGroup().location
param tag_values object

param local_tags object = {
  LastDeploy: utcNow('d')
} 

// Append LastDeploy tag to tag_values from parameter file
var all_tags = union(tag_values, local_tags)

param bdStorageAccountName string = 'bootdiag${uniqueString(resourceGroup().id)}'

resource sa 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  location: location
  name: bdStorageAccountName
  tags: all_tags
  sku: {
    name: bdStorageAccountSku
  }
  kind: bdStorageAccountKind
}
