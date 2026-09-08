#!/bin/bash
# Speaks the current time or a posture reminder, unless the screen is locked or a silencing
# Focus mode (Do Not Disturb / Sleep) is active.

set -u

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>/tmp/timespeak.log; }

# Select the announcement before the lock and Focus checks can delay it.
time_str=$(date +"%-l:%M")
message="It's $time_str"
case "${1-}" in
--scheduled)
	case "${time_str##*:}" in
	00 | 15 | 30 | 45) ;;
	10 | 20 | 40 | 50) message="posture" ;;
	*)
		log "skip: no announcement due"
		exit 0
		;;
	esac
	;;
"") ;;
*)
	printf 'Usage: %s [--scheduled]\n' "$0" >&2
	exit 2
	;;
esac

# 1. Skip if screen is locked.
locked=$(/usr/bin/swift -e '
import Quartz
if let d = CGSessionCopyCurrentDictionary() as? [String: Any],
   d["CGSSessionScreenIsLocked"] as? Int == 1 {
    print("1")
} else {
    print("0")
}
')
if [ "$locked" = "1" ]; then
	log "skip: screen locked"
	exit 0
fi

# 2. Skip if DND or Sleep focus is active.
#    Uses a macOS Shortcut ("Get Current Focus") because LaunchAgents
#    can't read ~/Library/DoNotDisturb/DB/ directly (TCC restriction).
focus=$(/usr/bin/shortcuts run "Get Current Focus" 2>/dev/null)
case "$focus" in
"Do Not Disturb" | "Sleep")
	log "skip: $focus active"
	exit 0
	;;
esac

# 3. Speak the selected announcement.
log "speak: $message"
/usr/bin/say "$message"
