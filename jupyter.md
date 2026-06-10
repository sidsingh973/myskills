# Skill: jupyter
Trigger: user types `/jupyter` (optionally with `status` or `reset`)

## What this skill does
Launches the Jupyter notebook playground and starts the output-sync watcher so
Claude can read all cell outputs (stdout, plots, errors) from a known directory.

Tool location: `~/.dobey/jupyter/nb_watcher.py`
Output directory: `~/.dobey/jupyter/outputs/`
Notebook: `~/.claude/workspace/scratch.ipynb` (or any .ipynb the user specifies)

---

## Step 1 — Parse the subcommand

Default (no arg or `/jupyter open`) → Step 2.
`/jupyter status` → Step 3.
`/jupyter reset` → Step 4.

---

## Step 2 — Default: open / start

### 2a. Ensure watcher is running (idempotent)
```bash
PIDFILE=~/.dobey/jupyter/.watcher.pid
NB=~/.claude/workspace/scratch.ipynb

if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
  echo "Watcher already running (PID $(cat $PIDFILE))"
else
  python3 ~/.dobey/jupyter/nb_watcher.py "$NB" &
  echo "Watcher started"
fi
```

### 2b. Check if Jupyter is running, start if not
```bash
if ! jupyter notebook list 2>/dev/null | grep -q localhost; then
  cd ~/.claude/workspace && jupyter notebook --no-browser &
  sleep 2
fi
jupyter notebook list
```

### 2c. Report to user
```
Notebook playground ready.
  Open: http://localhost:8888  →  scratch.ipynb
  Outputs syncing → ~/.dobey/jupyter/outputs/

Run cells normally (Shift+Enter). I'll see everything you produce.
Ask me: "what did cell 3 output?" or "show me the plot from cell 5"
```

---

## Step 3 — `status` subcommand

```bash
cat ~/.dobey/jupyter/outputs/manifest.json 2>/dev/null || echo "No outputs yet."
ls -lh ~/.dobey/jupyter/outputs/ 2>/dev/null
```

Report: last executed_at, cells with outputs, any cells with status=error.

---

## Step 4 — `reset` subcommand

Confirm with user first. Then:
```bash
rm -f ~/.dobey/jupyter/outputs/cell_*
```
Tell user: "Output cache cleared. Notebook source untouched. Use Kernel > Restart in Jupyter to reset the kernel."

---

## How Claude reads outputs

When the user asks "what did cell N produce?" or "show me the plot":

1. `Read(~/.dobey/jupyter/outputs/manifest.json)` — find which files belong to that cell.
2. For images: `Read(~/.dobey/jupyter/outputs/cell_N_img_0.png)` — renders inline (multimodal).
3. For text: `Read(~/.dobey/jupyter/outputs/cell_N_stdout.txt)`
4. For errors: `Read(~/.dobey/jupyter/outputs/cell_N_error.txt)`

manifest.json cell entry shape:
```json
{
  "index": 2,
  "execution_count": 3,
  "source_preview": "plt.plot(losses)",
  "status": "ok",
  "outputs": [
    {"type": "image", "file": "cell_2_img_0.png"},
    {"type": "stdout", "file": "cell_2_stdout.txt"}
  ],
  "error": null
}
```

## Programmatic execution (advanced)

To have Claude re-execute the whole notebook (not just read saved outputs):
```bash
python3 ~/.dobey/jupyter/nb_watcher.py scratch.ipynb --execute --once
```
Or start a watch loop that re-executes on every save:
```bash
python3 ~/.dobey/jupyter/nb_watcher.py scratch.ipynb --execute
```
