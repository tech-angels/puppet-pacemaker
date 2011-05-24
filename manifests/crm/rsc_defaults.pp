define ha::crm::rsc_defaults($value, $ignore_dc="false") {
  if($ha_cluster_dc == $hostname) or ($ha_cluster_dc == $fqdn) or ($ignore_dc == "true") {
    exec {
      "Setting rsc_defaults ${name} to ${value}":
        command => "/usr/sbin/crm -f - configure rsc_defaults ${name}=\"${value}\"",
        unless  => "/usr/sbin/crm -f - configure show |grep rsc_defaults -A 1|grep ${name}=\"${value}\"";
    }
  }
}
