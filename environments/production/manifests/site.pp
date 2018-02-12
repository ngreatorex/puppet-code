node 'raspi-monitoring.lan' {
	include local::linux
}

node 'raspi-puppet.win.lan' {
	include local::linux
}

node 'raspi-c.lan' {
	include local::linux
}

node 'raspi-weather.lan' {
	include local::linux
}

node 'raspi-e.win.lan' {

}

node default {

}
