class local::putty_curses {
  include ::profiled

  profiled::script { 'putty-curses.sh':
    content => 'export NCURSES_NO_UTF8_ACS=1',
  }

}
