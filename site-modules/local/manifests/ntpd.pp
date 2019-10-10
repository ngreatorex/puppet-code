class local::ntpd {
	if $trusted['hostname'] != "raspi-e" {
		class { 'ntp':
			servers => [ 'ntp.lan' ],
		}
	}
}