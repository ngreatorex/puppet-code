class local::linux {
	include local::putty_curses
	include local::ntpd
	include local::ansible
	include local::sudoers
	include ::profiled

	profiled::script { 'vim.sh':
		content => 'alias vim=vim.tiny',
	}

	profiled::script { 'ps1.sh':
		source => 'puppet:///modules/local/ps1.sh'
	}

	if $trusted['hostname'] != "raspi-e" {
		class { 'mit_krb5': 
			default_realm => 'WIN.LAN',
		}
	}

	sshd_config { "PermitRootLogin":
		ensure => present,
		value  => "no",
	}

	sshd_config { "GSSAPIAuthentication":
		ensure => present,
		value  => "yes",
	}

	package { 'rsyslog-relp':
		ensure => 'installed',
	}

	service { 'rsyslog':
		ensure => 'running',
	}

	package { 'lldpd':
		ensure => 'installed',
	}

	service { 'lldpd':
		ensure => 'running',
	}

	package { 'munin-node':
		ensure => 'installed',
	}

	service { 'munin-node':
		ensure => 'running',
	}

	package { 'libnet-dns-perl':
		ensure => 'installed',
		notify => Service['munin-node']
	}

	file { '/etc/rsyslog.d/relp.conf':
#		ensure => present,
#		source => 'puppet:///modules/local/relp.conf',
		ensure => absent,
		notify  => Service['rsyslog']
	}
	
	file { '/etc/rsyslog.d/diskstation.conf':
		ensure => present,
		source => 'puppet:///modules/local/syslog.conf',
		notify  => Service['rsyslog']
	}
}

