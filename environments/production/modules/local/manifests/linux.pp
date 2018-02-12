class local::linux {
	include local::putty_curses

	class { 'ntp':
	  servers => [ 'ntp.lan' ],
	}
}

