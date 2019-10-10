class local::sudoers {
	
	class { 'sudo': }

	sudo::conf { 'root':
		content => 'root	ALL=(ALL:ALL) NOPASSWD: ALL',
	}

	sudo::conf { 'sudo-group':
		priority => 10,
		content  => '%sudo	ALL=(ALL:ALL) NOPASSWD: ALL',
	}

	sudo::conf { 'ansible':
		priority => 50,
		content  => 'ansible	ALL=(ALL:ALL) NOPASSWD: ALL'
	}
}