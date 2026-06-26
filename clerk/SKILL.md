# /clerk — Start a clerk note-taker for this terminal

Starts a background clerk for the current terminal. It writes the same four layers as
the main clerks — log, raw, calls, and a shared status board — into the active project's
tracker. Tagging by project is done separately via `/route`.

## On invoke

1. Capture this terminal's TTY (must be done here — the daemon can't detect it):
```bash
tty
```

2. Suggest a name from the working directory:
```bash
basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_-'
```

3. **Ask the user to confirm or override the name.** Show: `Working in <PWD>. Name this clerk "<suggested>"? (enter to accept, or type a different name)`. Use the arg if `/clerk <name>` was given (skip the ask).

4. Reject names that collide with the four main clerks (`cofounder`, `coder`, `researcher`, `pm`) — those are owned by the main daemon. If collision, ask for a different name.

5. Start the watcher with the confirmed name:
```bash
python3 ~/Desktop/Koshai/infra/clerk/clerk.py watch <name> <tty>
```

6. Report the file paths it printed:
- Log: `~/Desktop/Koshai/infra/clerk/tracker/<name>_log_<date>.md`
- Tagged (after `/route`): `~/Desktop/Koshai/infra/clerk/tracker/<name>_tgd_<project>_<date>.md`
- Raw: `~/Desktop/Koshai/infra/clerk/tracker/raw/<name>_<date>.md`
- Calls: `~/Desktop/Koshai/infra/clerk/tracker/calls/<name>_<date>.md`
- Daemon log: `~/Desktop/Koshai/infra/clerk/clerk_<name>.log`

## To stop

```bash
python3 ~/Desktop/Koshai/infra/clerk/clerk.py watch-stop <name>
```

## Notes

- Name follows the terminal's folder, not the project. Two terminals in the same folder
  share a log file.
- `/clerk <name>` overrides auto-detection.
- To tag this clerk's log by project, run `/route <project>` in this same terminal.
