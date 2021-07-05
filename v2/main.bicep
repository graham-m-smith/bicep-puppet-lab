/* Parameters */

param project string = 'puppet2'
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
  {
    asgname: 'asg-https-inbound'
    priority: 120
    description: 'https-inbound'
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefixes: sourceAddressPrefixes
    sourcePortRange: '*'
    destinationPortRange: '443'
  }
  {
    asgname: 'asg-http-inbound'
    priority: 130
    description: 'http-inbound'
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefixes: sourceAddressPrefixes
    sourcePortRange: '*'
    destinationPortRange: '80'
  }
  {
    asgname: 'asg-ntopng-inbound'
    priority: 140
    description: 'ntopng-inbound'
    direction: 'Inbound'
    access: 'Allow'
    protocol: 'Tcp'
    sourceAddressPrefixes: sourceAddressPrefixes
    sourcePortRange: '*'
    destinationPortRange: '3000'
  }
]

/* Define array containing list of CNAME records to be created in Private DNS Zone */
var dnsCNAMEList = [
  {
    dnszone: dnsZoneName
    cname: 'puppet'
    target: 'puppetserver.${dnsZoneName}'
    ttl: 5
  }
]

/* Define array containing list of Linux Virtual machines to be created */
var linuxVMList = [
  {
    vmname: 'puppetserver'
    vmSize: 'Standard_DS2_v2'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS'
    spSku: '7.6'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.10'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: []
    applyScriptExtension: false
    fileUri: ''
    commandToExecute: ''
  }
  {
    vmname: 'puppetclient1'
    vmSize: 'Standard_DS2_v2'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS'
    spSku: '7.6'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.20'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: [
      {
        diskname: 'disk1'
        lun: 2
      }
    ]
    applyScriptExtension: false
    fileUri: ''
    commandToExecute: ''
  }
  {
    vmname: 'puppetclient2'
    vmSize: 'Standard_DS2_v2'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS'
    spSku: '7.6'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.30'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: [
      {
        diskname: 'disk1'
        lun: 2
      }
    ]
    applyScriptExtension: false
    fileUri: ''
    commandToExecute: ''
  }
  {
    vmname: 'puppetclient3'
    vmSize: 'Standard_DS2_v2'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS'
    spSku: '7.6'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.40'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: []
    applyScriptExtension: false
    fileUri: ''
    commandToExecute: ''
  }
  {
    vmname: 'puppetclient4'
    vmSize: 'Standard_B2s'
    spPublisher: 'OpenLogic'
    spOffer: 'CentOS-LVM'
    spSku: '7-lvm-gen2'
    spVersion: 'latest'
    privateIpAddress: '10.128.2.50'
    asglist: [
      'asg-ssh-inbound'
    ]
    autoShutdown: 'Enabled'
    autoShutdownTime: '2100'
    manageddisks: []
    applyScriptExtension: true
    fileUri: 'https://raw.githubusercontent.com/graham-m-smith/bicep-puppet-lab/master/deploy/deploy-puppet-client.sh'
    commandToExecute: 'sh deploy-puppet-client.sh'
  }
]

/*
vmsize: Standard_B2s

Publisher: OpenLogic
Offer: CentOS-LVM
Sku: 7-lvm-gen2
Version: latest

*/


/* Managed Disks */
var vmManagedDisks = [
  {
    vmname: 'puppetclient1'
    diskname: 'disk1'
    skuName: 'Standard_LRS'
    createOption: 'Empty'
    diskSize: 20
  }
  {
    vmname: 'puppetclient2'
    diskname: 'disk1'
    skuName: 'Standard_LRS'
    createOption: 'Empty'
    diskSize: 20
  }
]

/* Virtual Machine Backups - which machine to what vault/policy */
var vmBackups = [
  {
    vmname: 'puppetclient3'
    vmRG: resourceGroup().name
    backupVaultName: 'rsv-vault1'
    backupVaultRG: 'rg-rsv'
    backupPolicy: 'Daily'
  }
]

/* Create Application Security Groups */

module asg './asg.bicep' = {
  name: 'deployASG'
  params: {
    location: location
    rulesList: rulesList
  }
}

/* Create Network Security Group */

module nsg 'nsg.bicep' = {
  name: 'deployNSG'
  params: {
    location: location
    rulesList: rulesList
    nsgName: nsgName
  }
  dependsOn: [
    asg
  ]
}

/* Create Virtual Network & Subnet */

module vnet 'network.bicep'= {
  name: 'deployNetwork'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefixes: vnetAddressPrefixes
    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    nsgName: nsgName
  }
  dependsOn: [
    nsg
  ]
}

/* Bootdiag Storage Account */

module bd 'storageaccount.bicep' = {
  name: 'deployBootdiagSA'
  params: {
    location: location
    storageAccountName: bdStorageAccountName
    storageAccountSku: bdStorageAccountSku
    storageAccountKind: bdStorageAccountKind
  }
}

/* Private DNS Zone */

module privatedns 'privatedns.bicep' = {
  name: 'deployPrivateDns'
  params: {
    dnsZoneName: dnsZoneName
    vnetName: vnetName
  }
  dependsOn: [
    vnet
  ]
}

/* Private DNS CNAME records */

module privateDnsCNames 'privatednscnames.bicep' = {
  name: 'deployPrivateDnsCname'
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

module manageddisks 'manageddisk.bicep' = [for item in vmManagedDisks: {
  name: 'deploy-${item.vmname}-${item.diskname}'
  params: {
    location: location
    vmname: item.vmname
    diskname: item.diskname
    createOption: item.createOption
    skuName: item.skuName
    diskSize: item.diskSize
  }
}]

/* Deploy Linux Virtual Machines - Public Ip, NIC & VM */

module linuxvm 'vm-linux.bicep' = [for item in linuxVMList: {
  name: 'deployLinuxVM-${item.vmname}'
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
    fileUri: item.fileUri
    commandToExecute: item.commandToExecute
  }
  dependsOn: [
    asg
    nsg
    vnet
    bd
    manageddisks
  ]
}]

/* Add VMs to Backup Vault / Backup Policy */

module vmbackup 'vm-backup.bicep' = [for item in vmBackups: {
  name: 'deployVMBackup-${item.backupVaultName}-${item.backupPolicy}-${item.vmname}'
  scope: resourceGroup(item.backupVaultRG)
  params: {
    vmName: item.vmname
    vmResourceGroup: item.vmRG
    backupVaultName: item.backupVaultName
    rsvResourceGroup: item.backupVaultRG
    backupPolicyName: item.backupPolicy
    location: location
  }
  dependsOn: [
    linuxvm
  ]
}]
