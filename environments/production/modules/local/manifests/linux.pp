class local::linux {
	include local::putty_curses
	include ::profiled

	profiled::script { 'vim.sh':
		content => 'alias vim=vim.tiny',
	}

	class { 'ntp':
		servers => [ 'ntp.lan' ],
	}
}

