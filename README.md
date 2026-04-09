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
- **Focus detection:** calls `shortcuts run "Get Current Focus"`, which
  returns the active focus name (e.g. "Do Not Disturb", "Sleep") or
  empty string. LaunchAgents can't read `~/Library/DoNotDisturb/DB/`
  directly (TCC), but the `shortcuts` CLI has its own Apple entitlements.
- **Scheduling:** a LaunchAgent plist with four `StartCalendarInterval`
  entries (`:00 :15 :30 :45`).
- **Logging:** every run appends one line to `/tmp/timespeak.log` recording
  which branch it took (`skip: ...` or `speak: ...`). This is the only way
  to verify suppression is working without ear-testing.

## Prerequisites

Create a Shortcut called **"Get Current Focus"** in the Shortcuts app:

1. Open Shortcuts.app → New Shortcut
2. Add the **"Get Current Focus"** action
3. The shortcut should output the current focus name (or nothing)

This is needed because LaunchAgents are blocked by TCC from reading
`~/Library/DoNotDisturb/DB/` directly. The `shortcuts` CLI is an
Apple-signed binary with its own entitlements, so it can query focus
state without granting Full Disk Access.

## Usage

```
mise run test       # run once now
mise run bootstrap  # load the LaunchAgent into launchd
mise run bootout    # remove it
```

## Note on portability

The committed plist hardcodes the absolute path to `timespeak.sh`. If you
clone this repo to a path other than `/Users/jon/Dev/personal/timespeak`,
edit the `ProgramArguments` entry in `com.timespeak.agent.plist` before
running `mise run bootstrap`.
