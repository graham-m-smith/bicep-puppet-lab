param location string
param vmName string
param publicIPAllocationMethod string = 'Dynamic'
param privateIpAddress string
param asglist array
param vnetName string
param subnetName string
param spPublisher string
param spOffer string
param spSku string
param spVersion string
param vmSize string
param bdStorageAccountName string
param autoShutdown string
param autoShutdownTime string

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

/* Create Public IP */

resource publicip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: location
  name: publicIpName
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
  }
}

/* Create NIC */

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
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
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: spPublisher
        offer: spOffer
        sku: spSku
        version: spVersion
      }
      osDisk: {
        osType: 'Linux'
        name: osdiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        writeAcceleratorEnabled: false
      }
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

/* Configure automatic shutdown */

resource autoshutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
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

/* to do:
- auto shutdown schedule
- provisioning script
*/
