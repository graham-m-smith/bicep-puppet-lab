param dnsCNAMEList array

resource cname 'Microsoft.Network/privateDnsZones/CNAME@2020-06-01' = [for item in dnsCNAMEList: {
  name: '${item.dnszone}/${item.cname}'
  properties: {
    ttl: item.ttl
    cnameRecord: {
      cname: item.target
    }
  }
}]
