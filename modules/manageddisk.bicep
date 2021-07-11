param location string
param vmname string
param diskname string
param skuName string
param createOption string
param diskSize int
param tagValues object

var name = 'md-${vmname}-${diskname}'

resource disk 'Microsoft.Compute/disks@2020-12-01' = {
  name: name
  location: location
  tags: tagValues
  sku: {
    name: skuName
  }
  properties: {
    creationData: {
      createOption: createOption
    }
    diskSizeGB: diskSize
  }

}
