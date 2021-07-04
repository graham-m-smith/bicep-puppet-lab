/* The scope for this deployment is the RG where the vault exists */
/* deployment command: az deployment group create --resource-group rg-rsv --template-file main.bicep */

param location string = resourceGroup().location
param backupVaultName string = 'rsv-vault1'
param backupPolicyName string = 'Daily'
param rsvResourceGroup string = 'rg-rsv'
param vmName string = 'puppetclient2'
param vmResourceGroup string = 'rg-puppet2'

/* Create object for existing backup policy */
resource policy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' existing = {
  name: '${backupVaultName}/${backupPolicyName}'
  scope: resourceGroup(rsvResourceGroup)
}

/* Create object for existing VM to be backed up */
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' existing = {
  name: vmName
  scope: resourceGroup(vmResourceGroup)
}

/* Variables for adding VM to backup policy */
var fabricName = 'Azure'
var protectionContainers = 'IaasVMContainer;iaasvmcontainerv2;${vmResourceGroup};${vmName}'
var protectedItem = 'vm;iaasvmcontainerv2;${vmResourceGroup};${vmName}'

/* Output variables for debugging */
output outputProtectionContainers string = protectionContainers
output outputProtectedItem string = protectedItem

/* Add VM to backup policy */
resource vmbackup 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-03-01' = {
  name: '${backupVaultName}/${fabricName}/${protectionContainers}/${protectedItem}'
  location: location
  properties: {
    /*
    The 'Microsoft.Compute/virtualMachines' setting for protectedItemType causes a warning
    but it does deploy OK.
    Setting it to 'AzureIaaSVMProtectedItem' or 'AzureVmWorkloadProtectedItem' does not work
    on initial deployment, but does work on subsequent runs.
    I'm assuming this is a problem with bicep
    */
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: policy.id
    sourceResourceId: vm.id
  }
}
