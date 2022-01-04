# wacom-stylus-relative-speed
linux command line tool to change the movement speed of your wacom stylus.
It is just a workaround that `xsetwacom` does not have this function.

usage: wacom-stylus-relative-speed.sh [-u,--up|-d,--down <OFFSET_NUMBER>][-a,--align][-n,--notification][-h,--help]
  
  -u, --up <OFFSET_NUMBER>		Increase the speed level by <OFFSET_NUMBER>
  
  -d, --down <OFFSET_NUMBER>		Decrease the speed level by <OFFSET_NUMBER>
  
  -a, --align		According to the <OFFSET_NUMBER> you set, align the speed level with x1.0 . It is useful when you use keyboard shortcut to execute the command.
  
  -n, --notification		Send notification to desktop session. It is useful when you use keyboard shortcut to execute the command.(Require commandline tool "notify-send")
  
  -h, --help		Show this help then exit(without changing the speed).
  example:
	1) reset speed level to x1.0(if the <OFFSET_NUMBER> is 0, the speed level will reset to x1.0):
		wacom-stylus-relative-speed.sh -u 0
	2) increase speed level by offset 0.2:
		wacom-stylus-relative-speed.sh -u 0.2 -a
