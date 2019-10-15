class local::ntpd {
	if $trusted['hostname'] != "raspi-e" {
		class { 'ntp':
			servers => [ 'ntp.lan' ],
			restrict  => [
				'default nomodify notrap nopeer noquery',
				'-6 default nomodify notrap nopeer noquery'
				'127.0.0.1',
				'127.0.1.1',
				'-6 ::1',
			],
		}
	}
}
