# Modified 2011/5/24 by Gilbert Roulot

define ha::crm::location($ensure=present, $resource, $score, $rule_id = '', $rule_expr, $host = '', $ignore_dc="false") {
	if $rule_expr == '' and $host == '' {
		fail("Must specify one of rule or host in Ha::Crm::Location[${name}]")
	}
	if $rule_expr != '' and $host != '' {
		fail("Only one of rule and host can be specified in Ha::Crm::Location[${name}]")
	}
	
	if $rule_expr == '' {
		$loc = "${score}: ${host}"
	} else {
		$loc = "rule ${rule_id} ${score}: ${rule_expr}"
	}
	
	if($ha_cluster_dc == $hostname) or ($ha_cluster_dc == $fqdn) or ($ignore_dc == "true") {
		if($ensure == absent) {
			exec { "Removing location rule ${name}":
				command => "/usr/sbin/crm configure location delete ${name}",
				onlyif  => "/usr/sbin/crm configure show location ${name} > /dev/null 2>&1",
			}
		} else {
			exec { "Creating location rule ${name}":
				command => "/usr/sbin/crm configure location ${name} ${resource} ${loc}",
				unless  => "/usr/sbin/crm configure show location ${name} > /dev/null 2>&1",
			}
		}
	}
}
