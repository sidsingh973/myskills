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
