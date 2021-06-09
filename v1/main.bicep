
/* Parameters */

param location string = resourceGroup().location
param bdStorageAccountName string = 'bootdiag${uniqueString(resourceGroup().id)}'

/* KeyVault configuration: reference to existing KeyVault */

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'keyvault-gms'
  scope: resourceGroup('aad08023-4399-4859-b1a1-5baa25c80452', 'gms-key-vault-rg')
}

/* VNet / Subnet Configuration */

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet-puppet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.128.0.0/22'
      ]
    }
    subnets: [
      {
        name: 'subnet-puppet'
        properties: {
          addressPrefix: '10.128.2.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
  
}

/* Application Security Group Configuration */

resource asgssh 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = {
  name: 'asg-ssh-inbound'
  location: location
  
}

resource asgrdp 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = {
  name: 'asg-rdp-inbound'
  location: location
  
}

resource asghttps 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = {
  name: 'asg-https-inbound'
  location: location
  
}

resource asghttp 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = {
  name: 'asg-http-inbound'
  location: location
  
}

resource asgntopng 'Microsoft.Network/applicationSecurityGroups@2021-02-01' = {
  name: 'asg-ntopng-inbound'
  location: location
  
}

/* Network Security Group Configuration */

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-subnet-puppet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'ssh-inbound'
        properties: {
          priority: 100
          description:'ssh-inbound'
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefixes: [
            '86.22.9.178'
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asgssh.id
            }
          ]
          destinationPortRange: '22'
        }
      }
      {
        name: 'rdp-inbound'
        properties: {
          priority: 110
          description:'rdp-inbound'
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefixes: [
            '86.22.9.178'
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asgssh.id
            }
          ]
          destinationPortRange: '3389'
        }
      }
      {
        name: 'https-inbound'
        properties: {
          priority: 120
          description:'https-inbound'
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefixes: [
            '86.22.9.178'
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asghttps.id
            }
          ]
          destinationPortRange: '443'
        }
      }
      {
        name: 'http-inbound'
        properties: {
          priority: 130
          description:'http-inbound'
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefixes: [
            '86.22.9.178'
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asghttp.id
            }
          ]
          destinationPortRange: '80'
        }
      }
      {
        name: 'ntopng-inbound'
        properties: {
          priority: 140
          description:'ntopng-inbound'
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefixes: [
            '86.22.9.178'
          ]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [
            {
              id: asgntopng.id
            }
          ]
          destinationPortRange: '3000'
        }
      }
    ]
  }
}

/* BootDiag Storage Configuration */

resource bdstorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: bdStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  
}

/* Private DNS Zone Configuration */

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'gmslab.local'
  location: 'global'
}

resource privateDNSZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'gmslab.local/gmslab.local.link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork.id
    }
    registrationEnabled: true
  }
  dependsOn: [
    privateDNSZone
  ]
}

resource privateDNSZoneCNAME 'Microsoft.Network/privateDnsZones/CNAME@2020-06-01' = {
  name: 'gmslab.local/puppet'
  properties: {
    ttl: 5
    cnameRecord: {
      cname: 'puppetserver.gmslab.local'
    }
  }
  dependsOn: [
    privateDNSZone
  ]
}

/* Call module to create puppetserver VM */

module vm './vm_puppetserver.bicep' = {
  name: 'deployVMPuppetserver'
  params: {
    admin_username: keyVault.getSecret('username1')
    ssh_key: keyVault.getSecret('mac-ssh-key')
  }
  
}

