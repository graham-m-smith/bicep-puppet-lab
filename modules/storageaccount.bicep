param location string
param storageAccountName string
param storageAccountSku string
param storageAccountKind string
param tagValues object

resource sa 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  location: location
  name: storageAccountName
  tags: tagValues
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
}
