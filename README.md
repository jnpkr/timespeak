# timespeak

A replacement for macOS's "Announce the time" accessibility feature that
doesn't announce while you're asleep or on a call.

## Why

The built-in feature has no awareness of whether it's an appropriate moment
to talk. It will announce the time at 3am if the Mac is on, and it will
talk over you while you're on a call.

## What it does

Every 15 minutes, a LaunchAgent runs `timespeak.sh`, which speaks the time
via `say` — **unless** any of these are true, in which case it stays
silent:

- The screen is locked
- A **Do Not Disturb** focus is active
- A **Sleep** focus is active

Other focus modes are deliberately *not* treated as silencing — they're
working contexts, not "leave me alone" signals. If a call needs to suppress
announcements, turn on DND.

## How it works

- **Lock detection:** swift one-liner against `CGSessionCopyCurrentDictionary`
  reading `CGSSessionScreenIsLocked`. Uses the system `/usr/bin/swift`, no
  install needed.
- **Focus detection:** parses `~/Library/DoNotDisturb/DB/Assertions.json`
  and checks `storeAssertionRecords` for an active mode whose
  `assertionDetailsModeIdentifier` is `com.apple.donotdisturb.mode.default`
  or `com.apple.sleep.sleep-mode`.
- **Scheduling:** a LaunchAgent plist with four `StartCalendarInterval`
  entries (`:00 :15 :30 :45`).
- **Logging:** every run appends one line to `/tmp/timespeak.log` recording
  which branch it took (`skip: ...` or `speak: ...`). This is the only way
  to verify suppression is working without ear-testing.

## Usage

```
mise run test       # run once now
mise run install    # install the LaunchAgent
mise run uninstall  # remove it
```
