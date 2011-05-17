import "crm/primitive.pp"
import "stonith.pp"
import "ip.pp"

define ha::authkey($method, $key="") {
    file {
      '/etc/ha.d/authkeys':
        owner	=> 'root',
        group	=> 'root',
        mode	=> 0400,
        content	=> "# Managed by Puppet\nauth 1\n1 $method $key\n";
    }
}

define ha::heartbeat::conf(
$autojoin="any",
$use_logd="on",
$compression="bz2",
$keepalive="1",
$warntime="5",
$deadtime="10",
$initdead="60"
) {

  # Configure ha.cf
  common::concatfilepart {
    "ha.cf-0":
      file	=> '/etc/ha.d/ha.cf', 
      manage	=> true,
      content	=> template('pacemaker/ha.cf.erb'),
      notify	=> Service['heartbeat'];
  }
 

  case $operatingsystem {
    RedHat,CentOS: {
      case $operatingsystemrelease {
        5: {
          package {
            "pacemaker":
              ensure  => "1.0.4-23.1",
              require => Package["heartbeat"];
            "heartbeat":
              ensure => "2.99.2-8.1";
          }
        }
      }
    }
    Debian,Ubuntu: {
      package {
        "pacemaker":
          ensure  => installed,
          require => Package["heartbeat"];
        "heartbeat":
          ensure => installed;
        "openais":
          ensure => purged;
      }
    }
  }

  case $operatingsystem {
    # RHEL packages have this service bundled in with the heartbeat
    # packages.
    Debian,Ubuntu: {
      service {
        "logd":
          ensure    => running,
          hasstatus => true,
          enable    => true,
          require   => [Package["pacemaker"], Package["heartbeat"]];
        }
      }
  }
  service {
    "heartbeat":
      ensure    => running,
      hasstatus => true,
      enable    => true,
      require   => [Package["pacemaker"], Package["heartbeat"]];
  }

  file {
    # logd config, it's very simple and can be the same everywhere
    "/etc/logd.cf":
      ensure => present,
      mode   => 0440,
      owner  => "root",
      group  => "root",
      source => "puppet:///pacemaker/etc/logd.cf";
  }
        
  # Create node in ha.cf for all nodes
  @@ha::node_entry {
    $name:
      address	=> $ipaddress;
  } 

  # Collect nodes
  Ha::Node_entry<<| |>>
}

define ha::node_entry($port='694', $address) {
  common::concatfilepart {
    "ha.cf-8-node-$name":
      file	=> '/etc/ha.d/ha.cf', 
      manage	=> true,
      content	=> "node ${name}\n",
      notify	=> Service['heartbeat'];
  }
 
  if $pacemaker_shorewall_rules {
    # Allow udp traffic from node
    shorewall::rule {
      "Allow heartbeat traffic from $name":
        source            => "net:$address",
        destination       => '$FW',
        destinationport   => $port,
        proto             => 'udp',
        action            => 'ACCEPT',
        order             => '200';
    }
  }
}

define ha::mcast($group, $port=694, $ttl=1) {
  common::concatfilepart {
    "ha.cf-8-mcast-$name":
      file	=> '/etc/ha.d/ha.cf', 
      manage	=> true,
      content	=> "mcast ${interface} ${group} ${port} ${ttl} 0\n",
      notify	=> Service['heartbeat'];
  }
}

define ha::ucast($dev ) {
  common::concatfilepart {
    "ha.cf-8-ucast-$name":
      file	=> '/etc/ha.d/ha.cf', 
      manage	=> true,
      content	=> "ucast ${dev} ${name}\n",
      notify	=> Service['heartbeat'];
  }
}
