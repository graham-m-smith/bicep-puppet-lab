/* Parameters */

param project string = 'puppet3'
param dnsZoneName string = 'gmslab.local'
param location string = resourceGroup().location

param bdStorageAccountName string = 'bootdiag${uniqueString(resourceGroup().id)}'
param bdStorageAccountSku string = 'Standard_LRS'
param bdStorageAccountKind string = 'StorageV2'

param vnetAddressPrefixes array = [ 
  '10.128.0.0/22'
]
param subnetAddressPrefix string = '10.128.2.0/24'
param sourceAddressPrefixes string = '86.22.9.178'

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

/* Define array containing:
 - Application Security Group names
 - Network Security Group Rules 
*/
var rulesList = [
  {
    asgname: 'asg-ssh-inbound'
    priority: 100
    description: 'ssh-inbound'
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefixes: sourceAddressPrefixes
    sourcePortRange: '*'
    destinationPortRange: '22'
  }
  {
    asgname: 'asg-rdp-inbound'
    priority: 110
    description: 'rdp-inbound'
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefixes: sourceAddressPrefixes
    sourcePortRange: '*'
    destinationPortRange: '3389'
  }
]

/* Define array containing list of CNAME records to be created in Private DNS Zone */
var dnsCNAMEList = [
  {
    dnszone: dnsZoneName
    cname: 'puppet'
    target: 'puppet3server.${dnsZoneName}'
    ttl: 5
  }
]

/* Define array containing list of Linux Virtual machines to be created */
var linuxVMList = [
  {
    vmname: 'puppet3server'
    vmSize: 'Standard_DS2_v2'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS-LVM'
    spSku: '7-lvm-gen2'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.10'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: []
    applyScriptExtension: true
    extensionScriptName: 'configure-puppet-server'
    fileUri: 'https://raw.githubusercontent.com/graham-m-smith/bicep-puppet-lab/master/deploy/deploy-puppet-server.sh'
    commandToExecute: 'sh deploy-puppet-server.sh'
  }
  {
    vmname: 'puppet3client1'
    vmSize: 'Standard_B2s'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS-LVM'
    spSku: '7-lvm-gen2'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.20'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: []
    applyScriptExtension: true
    extensionScriptName: 'configure-puppet-client'
    fileUri: 'https://raw.githubusercontent.com/graham-m-smith/bicep-puppet-lab/master/deploy/deploy-puppet-client.sh'
    commandToExecute: 'sh deploy-puppet-client.sh'
  }
  {
    vmname: 'puppet3client2'
    vmSize: 'Standard_B2s'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS-LVM'
    spSku: '7-lvm-gen2'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.30'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: []
    applyScriptExtension: true
    extensionScriptName: 'configure-puppet-client'
    fileUri: 'https://raw.githubusercontent.com/graham-m-smith/bicep-puppet-lab/master/deploy/deploy-puppet-client.sh'
    commandToExecute: 'sh deploy-puppet-client.sh'
  }
]

/* Managed Disks */
var vmManagedDisks = [
  {
    vmname: 'puppet3client1'
    diskname: 'disk1'
    skuName: 'Standard_LRS'
    createOption: 'Empty'
    diskSize: 20
  }
  {
    vmname: 'puppet3client2'
    diskname: 'disk1'
    skuName: 'Standard_LRS'
    createOption: 'Empty'
    diskSize: 20
  }
]

/* Virtual Machine Backups - which machine to what vault/policy */
/* var vmBackups = [] */

/* Create Application Security Groups */

module asg '../modules/asg.bicep' = {
  name: 'deployASG-${project}'
  params: {
    location: location
    rulesList: rulesList
    tagValues: tagValues
  }
}

/* Create Network Security Group */

module nsg '../modules/nsg.bicep' = {
  name: 'deployNSG-${project}'
  params: {
    location: location
    rulesList: rulesList
    nsgName: nsgName
    tagValues: tagValues
  }
  dependsOn: [
    asg
  ]
}

/* Create Virtual Network & Subnet */

module vnet '../modules/network.bicep'= {
  name: 'deployNetwork-${project}'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefixes: vnetAddressPrefixes
    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    nsgName: nsgName
    tagValues: tagValues
  }
  dependsOn: [
    nsg
  ]
}

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

/* Private DNS Zone */

module privatedns '../modules/privatedns.bicep' = {
  name: 'deployPrivateDns-${project}'
  params: {
    dnsZoneName: dnsZoneName
    vnetName: vnetName
    tagValues: tagValues
  }
  dependsOn: [
    vnet
  ]
}

/* Private DNS CNAME records */

module privateDnsCNames '../modules/privatednscnames.bicep' = {
  name: 'deployPrivateDnsCname-${project}'
  params: {
    dnsCNAMEList: dnsCNAMEList
  }
  dependsOn: [
    privatedns
  ]
}

/* KeyVault configuration: reference to existing KeyVault */

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: 'keyvault-gms'
  scope: resourceGroup(keyvaultRgName)
}

/* Create Managed Disks */

module manageddisks '../modules/manageddisk.bicep' = [for item in vmManagedDisks: {
  name: 'deploy-${project}-${item.vmname}-${item.diskname}'
  params: {
    location: location
    vmname: item.vmname
    diskname: item.diskname
    createOption: item.createOption
    skuName: item.skuName
    diskSize: item.diskSize
    tagValues: tagValues
  }
}]

/* Deploy Linux Virtual Machines - Public Ip, NIC & VM */

module linuxvm '../modules/vm-linux.bicep' = [for item in linuxVMList: {
  name: 'deployLinuxVM-${project}-${item.vmname}'
  params: {
    location: location
    vnetName: vnetName
    subnetName: subnetName
    vmName: item.vmname
    vmSize: item.vmSize
    privateIpAddress: item.privateIpAddress
    asglist: item.asglist
    spPublisher: item.spPublisher
    spOffer: item.spOffer
    spSku: item.spSku
    spVersion: item.spVersion
    admin_username: keyVault.getSecret('username1')
    ssh_key: keyVault.getSecret('mac-ssh-key')
    bdStorageAccountName: bdStorageAccountName
    autoShutdown: item.autoShutdown
    autoShutdownTime: item.autoShutdownTime
    manageddisks: item.manageddisks
    applyScriptExtension: item.applyScriptExtension
    extensionScriptName: item.extensionScriptName
    fileUri: item.fileUri
    commandToExecute: item.commandToExecute
    tagValues: tagValues
  }
  dependsOn: [
    asg
    nsg
    vnet
    bd
    manageddisks
  ]
}]
