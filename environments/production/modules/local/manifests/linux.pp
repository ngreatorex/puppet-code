class local::linux {
	class { 'ntp':
	  servers => [ 'ntp.lan' ],
	}
}

