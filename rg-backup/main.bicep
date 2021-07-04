param location string = resourceGroup().location
param backupVaultName string = 'rsv-vault1'
param backupVaultSkuName string = 'RS0'
param backupVaultSkuTier string = 'Standard'
param backupVaultStorageModelType string = 'GeoRedundant'
param backupPolicyName string = 'Daily'

/* Create Recovery Services Vault */
resource rsv 'Microsoft.RecoveryServices/vaults@2021-03-01' = {
  name: backupVaultName
  location: location
  properties: {}
  sku: {
    name: backupVaultSkuName
    tier: backupVaultSkuTier
  }
}

/* RSV Storage Configuraiton */
resource rsvconfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2018-12-20' = {
  name: '${backupVaultName}/vaultstorageconfig'
  properties: {
    storageModelType: backupVaultStorageModelType
  }
  dependsOn: [
    rsv
  ]
}

/* Create VM Backup Policy in RSV */
resource rsvpolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' = {
  name: '${backupVaultName}/${backupPolicyName}'
  location: location
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '05:00'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '05:00'
        ]
        retentionDuration: {
          durationType: 'Days'
          count: 7
        }
      }
    }
    instantRpRetentionRangeInDays: 2
    timeZone: 'UTC'
  }
  dependsOn: [
    rsv
  ]
}

