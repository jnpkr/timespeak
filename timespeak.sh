#!/bin/bash
# Speaks the current time, unless the screen is locked or a silencing
# Focus mode (Do Not Disturb / Sleep) is active.

set -u

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>/tmp/timespeak.log; }

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

# 3. Speak the time.
time_str=$(date +"%-l:%M")
log "speak: $time_str"
/usr/bin/say "It's $time_str"
