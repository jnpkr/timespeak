#!/bin/bash
# Speaks the current time, unless the screen is locked or a silencing
# Focus mode (Do Not Disturb / Sleep) is active.

set -u

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> /tmp/timespeak.log; }

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
assertions="$HOME/Library/DoNotDisturb/DB/Assertions.json"
if [ -f "$assertions" ]; then
    silenced=$(/usr/bin/python3 - "$assertions" <<'PY'
import json, sys
SILENCING = {
    "com.apple.donotdisturb.mode.default",
    "com.apple.sleep.sleep-mode",
}
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    for entry in data.get("data", []):
        for rec in entry.get("storeAssertionRecords", []):
            mode = rec.get("assertionDetails", {}).get("assertionDetailsModeIdentifier")
            if mode in SILENCING:
                print("1")
                sys.exit(0)
    print("0")
except Exception:
    print("0")
PY
)
    if [ "$silenced" = "1" ]; then
        log "skip: DND or Sleep active"
        exit 0
    fi
fi

# 3. Speak the time.
time_str=$(date +"%l:%M" | sed 's/^ *//')
log "speak: $time_str"
/usr/bin/say "It's $time_str"
