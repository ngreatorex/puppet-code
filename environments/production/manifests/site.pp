node 'raspi-monitoring.lan' {
	include local::linux
}

node 'raspi-puppet.win.lan' {
	include local::linux
	class { 'puppetdb::master::config':
		puppetdb_server => 'ubuntu.lan'
	}
}

node 'raspi-c.lan' {
	include local::linux
}

node 'raspi-weather.lan' {
	include local::linux
}

node 'raspi-e.win.lan' {

}

node 'ubuntu.lan' {
	include local::linux
	include puppetdb
	class { 'puppetdb::master::config':
		puppet_confdir => '/etc/puppetlabs/puppet',
		puppet_conf => '/etc/puppetlabs/puppet/puppet.conf',
	}

	class {'::puppetexplorer':
		vhost_options => {
			rewrites  => [ { 
				rewrite_rule => ['^/api/metrics/v1/mbeans/puppetlabs.puppetdb.query.population:type=default,name=(.*)$  https://%{HTTP_HOST}/api/metrics/v1/mbeans/puppetlabs.puppetdb.population:name=$1 [R=301,L]'] 
			} ]
		}
	}

	class { 'apache::mod::wsgi': }
	class { 'puppetboard':
		manage_git        => true,
		manage_virtualenv => true,
		enable_catalog    => true,
	}
	class { 'puppetboard::apache::vhost':
		vhost_name => 'puppetboard.lan',
		port       => 80,
	}
}

node default {

}
