param project string
param keyvaultRgName string
param keyvaultName string
param vmName string
param vmSize string
param spPublisher string
param spOffer string
param spSku string
param spVersion string
param privateIpAddress string
param asglist array
param autoShutdown string
param autoShutdownTime string
param manageddisks array
param applyScriptExtension bool
param extensionScriptName string
param fileUri string
param commandToExecute string
param grantKeyVaultAccess bool
param identityType string
param location string = resourceGroup().location
param tag_values object

param local_tags object = {
  LastDeploy: utcNow('d')
} 

param bdStorageAccountName string = 'bootdiag${uniqueString(resourceGroup().id)}'

// Append LastDeploy tag to tag_values from parameter file
var all_tags = union(tag_values, local_tags)

var vnetName = 'vnet-${project}'
var subnetName = 'subnet-${project}'

/* KeyVault configuration: reference to existing KeyVault */

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyvaultName
  scope: resourceGroup(keyvaultRgName)
}

module vm 'vm-linux.bicep' = {
  name: 'deployLinuxVM-${project}-${vmName}'
  params: {
    admin_username: keyVault.getSecret('username1')
    applyScriptExtension: applyScriptExtension
    asglist: asglist
    autoShutdown: autoShutdown
    autoShutdownTime: autoShutdownTime
    bdStorageAccountName: bdStorageAccountName
    commandToExecute: commandToExecute
    extensionScriptName: extensionScriptName
    fileUri: fileUri
    grantKeyVaultAccess: grantKeyVaultAccess
    identityType: identityType
    location: location
    manageddisks: manageddisks
    privateIpAddress: privateIpAddress
    spOffer: spOffer
    spPublisher: spPublisher
    spSku: spSku
    spVersion: spVersion
    ssh_key: keyVault.getSecret('mac-ssh-key')
    subnetName: subnetName
    tagValues: all_tags
    vmName: vmName
    vmSize: vmSize
    vnetName: vnetName
  }
}
