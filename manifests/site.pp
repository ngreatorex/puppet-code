node 'raspi-a.lan' {
	include local::linux
}

node 'raspi-b.lan' {
	include local::linux
}

node 'raspi-c.lan' {
	include local::linux
}

node 'raspi-d.lan' {
	include local::linux
}

node 'raspi-e.win.lan' {
	include local::linux
}

node 'raspi-weather.lan' {
	include local::linux
}

node 'ubuntu.lan' {
	include local::linux
	include puppetdb
	class { 'puppetdb::master::config':
		puppet_confdir => '/etc/puppetlabs/puppet',
		puppet_conf => '/etc/puppetlabs/puppet/puppet.conf',
	}

#	class {'::puppetexplorer':
#		vhost_options => {
#			rewrites  => [ { 
#				rewrite_rule => ['^/api/metrics/v1/mbeans/puppetlabs.puppetdb.query.population:type=default,name=(.*)$  https://%{HTTP_HOST}/api/metrics/v1/mbeans/puppetlabs.puppetdb.population:name=$1 [R=301,L]'] 
#			} ]
#		}
#	}

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

	class { 'apache::mod::proxy': }
	apache::vhost { 'ansible.lan': 
		port	=> 80,
		docroot => '/var/www/html',
		servername => 'ansible.lan',
		proxy_dest => 'http://localhost:8000'
	}
	apache::vhost { 'kibana.lan': 
		port	=> 80,
		docroot => '/var/www/html',
		servername => 'kibana.lan',
		proxy_dest => 'http://localhost:32768'
	}
}

node default {

}
