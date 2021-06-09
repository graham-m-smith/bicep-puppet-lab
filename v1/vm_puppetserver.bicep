
param location string = resourceGroup().location

@secure()
param admin_username string

@secure()
param ssh_key string

/* Reference to existing application security group */
resource asgssh 'Microsoft.Network/applicationSecurityGroups@2021-02-01' existing = {
  name: 'asg-ssh-inbound'
  scope: resourceGroup('aad08023-4399-4859-b1a1-5baa25c80452', resourceGroup().name)
}

/* Public IP Configuration */

resource puppetserverPublicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'public-ip-puppetserver'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
} 

/* NIC Configuration */

resource puppetserverNic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'nic-puppetserver'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-puppetserver'
        properties: {
          publicIPAddress: {
            id: puppetserverPublicIp.id
            }
          privateIPAddress: '10.128.2.10'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-puppet', 'subnet-puppet')
          }
          applicationSecurityGroups: [
            {
              id: asgssh.id
            }
          ]
        }
      }
    ]
  }
  
}

/* Virtual Machine Configuration */

resource puppetserverVM 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'puppetserver'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'OpenLogic'
        offer: 'CentOS'
        sku: '7.6'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'osdisk-puppetserver'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        writeAcceleratorEnabled: false
      }
    }
    osProfile: {
      computerName: 'puppetserver'
      adminUsername: admin_username
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/graham/.ssh/authorized_keys'
              keyData: ssh_key
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
        }
      }
      secrets: [
        
      ]
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: puppetserverNic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
  
}
