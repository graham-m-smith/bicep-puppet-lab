param location string
param backupVaultName string 
param backupPolicyName string
param rsvResourceGroup string
param vmName string
param vmResourceGroup string

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

/* Add VM to backup policy */
resource vmbackup 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-03-01' = {
  name: '${backupVaultName}/${fabricName}/${protectionContainers}/${protectedItem}'
  location: location
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: policy.id
    sourceResourceId: vm.id
  }
}

