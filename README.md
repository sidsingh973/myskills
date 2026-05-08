# myskills

Custom skills for [Claude Code](https://claude.ai/code).

## Install all skills

```bash
curl -fsSL https://raw.githubusercontent.com/sidsingh973/myskills/main/install.sh | bash
```

Then restart Claude Code. All skills will be available as `/skillname`.

---

## Skills

### /wincap
Takes a screenshot of your screen and lets Claude analyze it.
```
/wincap
```

### /savemem
Saves the current session to `~/.claude/session_memory.md` so you can resume later.
```
/savemem
```

### /prevmem
Loads the previously saved session so you can pick up where you left off.
```
/prevmem
```

### /dobeypilot
AI co-pilot that controls any desktop app through natural language using screenshots + macOS Accessibility API.
```
/dobeypilot HEC-HMS
```
See [dobeypilot/README.md](dobeypilot/README.md) for full documentation.

---

## App knowledge library

Verified AX element maps and workflows for specific apps: [apps/](apps/)

| App | Docs |
|-----|------|
| [HEC-HMS 4.13](apps/HEC-HMS.json) | [Full docs →](apps/hec-hms/) |

## Session history

Per-app running notes: [sessions/](sessions/)
