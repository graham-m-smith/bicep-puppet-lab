/* Parameters */

param project string = 'puppetlab'
param dnsZoneName string = 'gmslab.local'
param location string = resourceGroup().location

param bdStorageAccountName string = 'bootdiag${uniqueString(resourceGroup().id)}'
param bdStorageAccountSku string = 'Standard_LRS'
param bdStorageAccountKind string = 'StorageV2'

param keyvaultRgName string = 'gms-key-vault-rg'

param tagValues object = {
  Department: 'Infrastrucrure'
  Business_Unit: 'TIS'
  Environment: 'Playground'
  DeployMethod: 'Bicep'
  LastDeploy: utcNow('d')
  UpdateGroup: 'Tuesday1'
}

var vnetName = 'vnet-${project}'
var subnetName = 'subnet-${project}'
var nsgName = 'nsg-${subnetName}'

param vmName string = 'puppet-alma'
param publicIPAllocationMethod string = 'Dynamic'
param privateIpAddress string = '10.128.2.40'

/* Bootdiag Storage Account */

module bd '../modules/storageaccount.bicep' = {
  name: 'deployBootdiagSA-${project}'
  params: {
    location: location
    storageAccountName: bdStorageAccountName
    storageAccountSku: bdStorageAccountSku
    storageAccountKind: bdStorageAccountKind
    tagValues: tagValues
  }
}

/* KeyVault configuration: reference to existing KeyVault */

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'keyvault-gms'
  scope: resourceGroup(keyvaultRgName)
}

@secure()
param admin_username string

@secure()
param ssh_key string

var publicIpName = 'public-ip-${vmName}'
var nicName = 'nic-${vmName}'
var ipconfigName = 'ipconfig-${vmName}'
var osdiskName = 'osdisk-${vmName}'
var sshKeyPath = '/home/${admin_username}/.ssh/authorized_keys'
var env = environment()
var bdStorageAccountUri = 'https://${bdStorageAccountName}.blob.${env.suffixes.storage}'

var asglist = [
  'asg-ssh-inbound'
]

var manageddisks = []
var autoShutdown = 'Enabled'
var autoShutdownTime = '21:00'
var grantKeyVaultAccess = true
var applyScriptExtension = false
var extensionScriptName = 'none'
var fileUri = 'none'
var commandToExecute = 'none'

/* Create Public IP */

resource publicip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: location
  name: publicIpName
  tags: tagValues
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
  }
}

/* Create NIC */

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  tags: tagValues
  properties: {
    ipConfigurations: [
      {
        name: ipconfigName
        properties: {
          publicIPAddress: {
            id: publicip.id
          }
          privateIPAddress: privateIpAddress
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          applicationSecurityGroups: [for item in asglist: {
            id: resourceId('Microsoft.Network/applicationSecurityGroups', item)
          }]

        }

      }
    ]
  }
  dependsOn: [
    publicip
  ]
}

/* Create Virtual Machine */

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  tags: tagValues
  identity: {
    type: 'SystemAssigned'
  }
  plan: {
    name: 'almalinux-9-latest'
    product: 'almalinux-9-latest'
    publisher: 'procomputers'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2ds_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'procomputers'
        offer: 'almalinux-9-latest'
        sku: 'almalinux-9-latest'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: osdiskName
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        caching: 'ReadWrite'
        writeAcceleratorEnabled: false
      }
      dataDisks: [for item in manageddisks: {
        name: 'md-${vmName}-${item.diskname}'
        managedDisk: {
          id: resourceId('Microsoft.Compute/disks', 'md-${vmName}-${item.diskname}')
        }
        lun: item.lun
        createOption: 'Attach'
        caching: 'ReadWrite'
        
      }]
    }
    osProfile: {
      computerName: vmName
      adminUsername: admin_username
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: sshKeyPath
              keyData: ssh_key
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: bdStorageAccountUri
      }
    }
  }
}

output principalId string = vm.identity.principalId

/* Configure automatic shutdown */

resource autoshutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  tags: tagValues
  properties: {
    status: autoShutdown
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: 'GMT Standard Time'
    targetResourceId: resourceId('Microsoft.Compute/virtualMachines', vmName)
  }
  dependsOn: [
    vm
  ]
}

var keyVaultPermissions = {
  secrets: [ 
    'get'
  ]
}

/* Grant VM Access to KeyVault */
module keyVaultAccess '../modules/keyvaultpolicy.bicep' = if (grantKeyVaultAccess) {
  scope: resourceGroup('gms-key-vault-rg')
  dependsOn: [
    vm
  ]
  name: 'KeyVaultAccess-${vmName}'
  params: {
    keyVaultName: 'keyvault-gms'
    principalId: vm.identity.principalId
    keyVaultPermissions: keyVaultPermissions
    policyAction: 'add'
  }
}

/* Add custom script extension */

resource customscript 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (applyScriptExtension) {
  name: '${vmName}/${extensionScriptName}'
  location: location
  tags: tagValues
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        fileUri
      ]
      commandToExecute: commandToExecute
    }
  }
  dependsOn: [
    vm
    keyVaultAccess
  ]
}
