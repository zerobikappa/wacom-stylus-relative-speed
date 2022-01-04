#!/bin/bash

function error_message(){
	case "$1" in
		-1)
			echo "Cannot find any wacom device." >&2
			[ $DESKTOP_NOTIFICATION_FLAG -eq 1 ] && notify-send -a "wacom-stylus-relative-speed" error "Cannot find any wacom device."
			;;
		-2)
			echo "This stylus seems not in relative mode. No action was taken." >&2
			[ $DESKTOP_NOTIFICATION_FLAG -eq 1 ] && notify-send -a "wacom-stylus-relative-speed" error "This stylus seems not in relative mode.\nNo action was taken."
			;;
		-3)
			echo "error: You cannot use --up and --down at the sametime" >&2
			[ $DESKTOP_NOTIFICATION_FLAG -eq 1 ] && notify-send -a "wacom-stylus-relative-speed" error "You cannot use --up and --down at the sametime"
			;;
		-4)
			echo "please at least use one of --up or --down option" >&2
			[ $DESKTOP_NOTIFICATION_FLAG -eq 1 ] && notify-send -a "wacom-stylus-relative-speed" error "Please at least use one of --up or --down option"
			;;
		-5)
			echo "too slow" >&2
			[ $DESKTOP_NOTIFICATION_FLAG -eq 1 ] && notify-send -t 1000 -a "wacom-stylus-relative-speed" "too slow" "stylus id=$STYLUS_ID\nxinput ACD=$PROP_ARG\nspeed level=x$SPEED_LEVEL"
			;;
		-6)
			echo "too fast" >&2
			[ $DESKTOP_NOTIFICATION_FLAG -eq 1 ] && notify-send -t 1000 -a "wacom-stylus-relative-speed" "too fast" "stylus id=$STYLUS_ID\nxinput ACD=$PROP_ARG\nspeed level=x$SPEED_LEVEL"
			;;
		*)
			echo "no such error message."
			;;
	esac
	echo "Please use option -h or --help for usage information."
}

function print_help(){
	cat << EOF
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

EOF

}


parameters=`getopt -o u:d:ahn --long up:,down:,align,help,notification -n "$0" -- "$@"`

DESKTOP_NOTIFICATION_FLAG=0
eval set -- "$parameters"
while true ; do
	case "$1" in
		-h| --help)
			print_help
			exit ;;
		-u| --up)
			UP_OR_DOWN_FLAG=1
			ARG_OFFSET=$2
			shift 2 ;;
		-d| --down)
			UP_OR_DOWN_FLAG=-1
			ARG_OFFSET=$2
			shift 2 ;;
		-a| --align)
			OUTPUT_LEVEL_ALIGN_FLAG=1
			shift ;;
		-n| --notification)
			DESKTOP_NOTIFICATION_FLAG=1
			shift ;;
		--) break ;;
		*)
			print_help
			exit;
	esac
done

{ echo "$parameters" | grep -E '\-\-up|\-u ' | grep -E '\-\-down|\-d ' ; } &>/dev/null
if [ $? -eq 0 ];
	then error_message -3
		exit 3
fi

{ echo "$parameters" | grep -E '\-\-up|\-\-down|\-u |\-d ' ; } &>/dev/null
if [ $? -ne 0 ];
	then
		error_message -4
		exit 4
fi

STYLUS_ID=`xsetwacom --list|grep -i "type: stylus"|sed "s/^.*id\: //"|awk '{print $1}'`
if [ -z "$STYLUS_ID" ]
	then 
		error_message -1
		exit 1
fi

MODE_STATUS=`xsetwacom --get $STYLUS_ID mode|tr '[A-Z]' '[a-z]'`
if [ $MODE_STATUS != "relative" ]
	then
		error_message -2
		exit 2
fi


PROP_OPTION_ID=`xinput --list-props $STYLUS_ID|grep -i "Accel Constant Deceleration" |sed "s/^.*(//" |sed "s/).*$//"`
PROP_ARG=`xinput --list-props $STYLUS_ID|grep -i "Accel Constant Deceleration" |awk '{print $NF}'`
SPEED_LEVEL=$(printf "%0.7f" $(echo "scale = 8; 1 / $PROP_ARG" | bc))
if [ $OUTPUT_LEVEL_ALIGN_FLAG -eq 1 ]
	then
		[ $(echo "$ARG_OFFSET != 0" |bc) -eq 1 ] && ALIGN_MULTI=$(printf "%.0f" $(echo "scale = 8; ($SPEED_LEVEL - 1) / $ARG_OFFSET" |bc)) || ALIGN_MULTI=0
			#if $ARG_OFFSET is 0, $ALIGN_MULTI will be not important. 
		SPEED_LEVEL=$(echo "scale = 8; $ALIGN_MULTI * $ARG_OFFSET + 1" |bc)
fi


NEW_SPEED_LEVEL=$(echo "scale = 8; $SPEED_LEVEL + ($UP_OR_DOWN_FLAG * $ARG_OFFSET)" |bc)
if [ $(echo "$NEW_SPEED_LEVEL <= 0" |bc) -eq 1 ]
	then
		error_message -5
		exit 5
fi

if [ $(echo "$NEW_SPEED_LEVEL > 3" |bc) -eq 1 ]
	then
		error_message -6
		exit 6
fi
SPEED_LEVEL=$NEW_SPEED_LEVEL


PROP_ARG=$(echo "scale = 8; 1 / $SPEED_LEVEL" |bc)


xinput set-prop $STYLUS_ID $PROP_OPTION_ID $PROP_ARG && echo "Succeeded. Now the xinput Accel_Constant_Deceleration of your stylus id<$STYLUS_ID> was changed to $PROP_ARG."
echo -e "stylus id=$STYLUS_ID\nxinput ACD=$PROP_ARG\nspeed level=x$SPEED_LEVEL"
[ $DESKTOP_NOTIFICATION_FLAG -eq 1 ] && notify-send -t 1000 -a "wacom-stylus-relative-speed" "succeeded" "stylus id=$STYLUS_ID\nxinput ACD=$PROP_ARG\nspeed level=x$SPEED_LEVEL"
