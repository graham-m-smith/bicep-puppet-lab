param keyVaultName string
param principalId string
param keyVaultPermissions object
param policyAction string

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
  resource keyVaultPolicies 'accessPolicies' = {
    name: policyAction
    properties: {
      accessPolicies: [
        {
          objectId: principalId
          permissions: keyVaultPermissions
          tenantId: subscription().tenantId
        }
      ]
    }
  }
}
