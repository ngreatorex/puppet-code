class local::ansible {
	user { 'ansible': 
		ensure => 'present',
		managehome => 'yes',
		home => '/var/lib/ansible',
		purge_ssh_keys => true,
	}

	ssh_authorized_key { 'ansible': 
		ensure => present,
		user => 'ansible',
		type => 'ssh-rsa',
		key => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCoLd5/j5m/yM45xbP9ErChvEGzYWQwB3nukN/fNnSGdPF6Zrgg1PDwFziMH7+Dhtvy/aCsRfxo6LywDNHqOGA2mR+n2n6086mH5bJOADerHS4ncZLMh+KSmQNWWLxQh6dAJjlhfnugVwpN3+z3Qm78OzTh5UNJXEX/1MZjKXT11xyTr6jnVOSlOuHC1AE1gLjR+DqNt7cN8QCMDFlp1o9QIr2uiS5bTaPT/E/7GlNw1RF842BVx9lOEHYXt4SH+ho5dyfd/KJ35791PAzOfQBjfIDcp5fzdV+OmTSaiBGmPPM4AcUZ62cAGddS4zY+Fl73XOk5dighJTcTXnLVpegP',
	}
}