# timespeak

A replacement for macOS's "Announce the time" accessibility feature that
doesn't announce while you're asleep or on a call.

## Why

The built-in feature has no awareness of whether it's an appropriate moment
to talk. It will announce the time at 3am if the Mac is on, and it will
talk over you while you're on a call.

## What it does

A LaunchAgent runs `timespeak.sh --scheduled` to speak the time or say
"posture" via `say`, on these minute boundaries each hour:

| Minutes | Announcement |
| --- | --- |
| :00, :15, :30, :45 | Current time |
| :10, :20, :40, :50 | "posture" |

Posture reminders fall on ten-minute boundaries, but time announcements
take priority at :00 and :30. Only one announcement plays per scheduled
minute. Missed reminders are not queued for catch-up; runs outside the
scheduled minutes stay silent.

Both announcements stay silent when any of these are true:

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
- **Scheduling:** a LaunchAgent plist with eight `StartCalendarInterval`
  entries (`:00 :10 :15 :20 :30 :40 :45 :50`). The script selects the
  announcement using the current minute when it starts.
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

```sh
mise run test       # run once now
mise run bootstrap  # load the LaunchAgent into launchd
mise run bootout    # remove it
```

## Note on portability

The committed plist hardcodes the absolute path to `timespeak.sh`. If you
clone this repo to a path other than `/Users/jon/Dev/personal/timespeak`,
edit the `ProgramArguments` entry in `com.timespeak.agent.plist` before
running `mise run bootstrap`.
