#!/bin/bash
# Speaks the current time or a posture reminder, unless the screen is locked, an app is
# using microphone input, or a silencing Focus mode (Do Not Disturb / Sleep) is active.

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

# 1. Skip if the screen is locked or an app is using microphone input.
system_state=$(/usr/bin/swift -e '
import CoreAudio
import Foundation
import Quartz

if let d = CGSessionCopyCurrentDictionary() as? [String: Any],
   d["CGSSessionScreenIsLocked"] as? Int == 1 {
    print("locked")
} else {
    do {
        let microphoneActive = try AudioHardwareSystem.shared.processes.contains { process in
            try process.isRunningInput
        }
        print(microphoneActive ? "microphone-active" : "clear")
    } catch {
        fputs("timespeak: system state check failed: \(error)\n", stderr)
        exit(1)
    }
}
')

case "$system_state" in
locked)
	log "skip: screen locked"
	exit 0
;;
microphone-active)
	log "skip: microphone active"
	exit 0
;;
clear) ;;
*)
	log "skip: system state check failed"
	exit 0
;;
esac

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
