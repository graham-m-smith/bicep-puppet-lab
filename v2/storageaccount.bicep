param location string
param storageAccountName string
param storageAccountSku string
param storageAccountKind string

resource sa 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  location: location
  name: storageAccountName
  sku: {
    name: storageAccountSku
  }
  kind: storageAccountKind
}
