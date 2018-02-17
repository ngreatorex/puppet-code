class local::linux {
	include local::putty_curses
	include ::profiled

	profiled::script { 'vim.sh':
		content => 'alias vim=vim.tiny',
	}

	class { 'ntp':
		servers => [ 'ntp.lan' ],
	}

	class { 'mit_krb5': 
		default_realm => 'WIN.LAN',
	}

	sshd_config { "PermitRootLogin":
		ensure => present,
		value  => "no",
	}

	sshd_config { "GSSAPIAuthentication":
		ensure => present,
		value  => "yes",
	}
}

