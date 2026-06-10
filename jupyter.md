# Skill: jupyter
Trigger: user types `/jupyter` (optionally with a path, `status`, `stop`, or `reset`)

## What this skill does
Launches JupyterLab in a browser (folder tree left, notebook right) with the kernel
auto-wired to the project's Python environment. nb_watcher syncs all cell outputs so
Claude can read stdout, plots, and errors without any manual steps.

Launcher: `~/.dobey/jupyter/launch_jupyter.sh`
Outputs:  `~/.dobey/jupyter/outputs/`

---

## Step 1 — Parse the subcommand

- `/jupyter` or `/jupyter open` → Step 2, WORKDIR = current working directory (pwd)
- `/jupyter <path>` (absolute or ~ path) → Step 2, WORKDIR = that path
- `/jupyter run <code>` → Step 6 (execute code immediately, no browser needed)
- `/jupyter status` → Step 3
- `/jupyter stop` → Step 4
- `/jupyter reset` → Step 5

---

## Step 2 — Default: launch

Run this Bash command, passing the resolved WORKDIR:

```bash
bash ~/.dobey/jupyter/launch_jupyter.sh "$(pwd)"
```

Or with a path argument:
```bash
bash ~/.dobey/jupyter/launch_jupyter.sh "/path/to/project"
```

Show the full script output to the user verbatim. The script handles everything:
uv detection, env detection, ipykernel install, kernel registration, server startup,
idempotency check, browser open, watcher start, and confirmation.

If the script exits with code 1, show the error and stop — do not retry.

---

## Step 3 — `status` subcommand

```bash
cat ~/.dobey/jupyter/outputs/manifest.json 2>/dev/null || echo "No outputs yet."
```

Also check liveness:
```bash
# Server
RUNTIME_DIR=$(python3 -c "from jupyter_core.paths import jupyter_runtime_dir; print(jupyter_runtime_dir())")
ls "$RUNTIME_DIR"/jpserver-*.json 2>/dev/null | wc -l

# Watcher
[ -f ~/.dobey/jupyter/.watcher.pid ] && kill -0 $(cat ~/.dobey/jupyter/.watcher.pid) 2>/dev/null && echo "watcher alive" || echo "watcher not running"
```

Report to user:
- Server: running / not running
- Watcher: alive / not running
- Last sync: manifest.json `executed_at` field
- Cell count and any cells with `status: "error"` (show ename + evalue)

---

## Step 4 — `stop` subcommand

```bash
# Kill all running Jupyter servers
RUNTIME_DIR=$(python3 -c "from jupyter_core.paths import jupyter_runtime_dir; print(jupyter_runtime_dir())")
for f in "$RUNTIME_DIR"/jpserver-*.json; do
  [ -f "$f" ] || continue
  pid=$(python3 -c "import json; print(json.load(open('$f'))['pid'])" 2>/dev/null)
  [ -n "$pid" ] && kill "$pid" 2>/dev/null && echo "Stopped server PID $pid" && rm -f "$f"
done

# Kill watcher
WPID_FILE=~/.dobey/jupyter/.watcher.pid
if [ -f "$WPID_FILE" ]; then
  kill $(cat "$WPID_FILE") 2>/dev/null && echo "Stopped watcher."
  rm -f "$WPID_FILE"
fi
```

Tell user: "Jupyter stopped. Run /jupyter to restart."

---

## Step 5 — `reset` subcommand

Confirm with user first. Then:
```bash
rm -f ~/.dobey/jupyter/outputs/cell_*
```

Tell user: "Output cache cleared. Notebook source untouched. Use Kernel → Restart Kernel
in JupyterLab to reset the kernel state."

---

## How Claude reads outputs

When the user asks "what did cell N produce?" or "show me the plot from cell 2":

1. `Read(~/.dobey/jupyter/outputs/manifest.json)` — find which files belong to that cell
2. For text: `Read(~/.dobey/jupyter/outputs/cell_N_stdout.txt)`
3. For images: `Read(~/.dobey/jupyter/outputs/cell_N_img_0.png)` — renders inline (multimodal)
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

---

## Step 6 — `run` subcommand (agents: no browser needed)

Execute code directly in the project kernel. Output appears immediately in the terminal.
Plots are saved to `~/.dobey/jupyter/outputs/` and readable via manifest.

**Single line:**
```bash
python3 ~/.dobey/jupyter/exec.py "$(pwd)" "print(1 + 1)"
```

**Multi-line code — write to a temp file, then run:**
```bash
cat > /tmp/jupyter_run.py << 'PYEOF'
%matplotlib inline
import matplotlib.pyplot as plt
import numpy as np

x = np.linspace(0, 2 * np.pi, 200)
fig, ax = plt.subplots(figsize=(6, 3))
ax.plot(x, np.sin(x), label="sin(x)")
ax.plot(x, np.cos(x), label="cos(x)")
ax.legend()
ax.set_title("sin and cos")
plt.tight_layout()
plt.show()
print("plot done")
PYEOF
python3 ~/.dobey/jupyter/exec.py "$(pwd)" --file /tmp/jupyter_run.py
```

What comes back:
- stdout printed directly to terminal
- `[plot → ~/.dobey/jupyter/outputs/cell_0_<ts>_plot_0.png]` if there's a figure
- STDERR printed to stderr if there's an error
- manifest.json updated automatically — no separate watcher step needed

To read the plot Claude just produced:
```
Read(~/.dobey/jupyter/outputs/cell_0_<ts>_plot_0.png)
```
Or check manifest first: `cat ~/.dobey/jupyter/outputs/manifest.json`

---

## Programmatic execution (advanced)

To have Claude re-execute the whole notebook (not just read saved outputs):
```bash
python3 ~/.dobey/jupyter/nb_watcher.py scratch.ipynb --execute --once
```
Or start a watch loop that re-executes on every save:
```bash
python3 ~/.dobey/jupyter/nb_watcher.py scratch.ipynb --execute
```
