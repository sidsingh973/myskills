---
name: lit-scan
description: Zero-token gather from arXiv, HN, and Reddit. Returns ranked source list for Researcher to synthesize.
---

# /lit-scan — Source Gather

Run a zero-token literature scan across arXiv, HN, and Reddit. Fetches and ranks sources;
Researcher only reads and synthesizes. No LLM tokens spent on the gather step.

## Usage

```bash
python3 ~/Desktop/Koshai/infra/lib/researcher/lit_scan.py "<question>"
python3 ~/Desktop/Koshai/infra/lib/researcher/lit_scan.py "<question>" --limit 10
python3 ~/Desktop/Koshai/infra/lib/researcher/lit_scan.py "<question>" --sources arxiv,hn
python3 ~/Desktop/Koshai/infra/lib/researcher/lit_scan.py "<question>" --sources reddit --limit 8
```

## Sources
- `arxiv` — academic papers, ranked by relevance
- `hn` — Hacker News stories, ranked by points
- `reddit` — Reddit posts, ranked by relevance

Default: all three, 5 results each = 15 sources total.

## Output format

```
[N] [SOURCE] Title
    Key line (abstract excerpt / points / subreddit)
    URL
```

## When to use

- Before any research task — run this first to find sources, then read and synthesize
- Competitive scans (hn + reddit for product demand signals)
- Academic grounding (arxiv for papers)
- Prior art checks (all three)

## What it does NOT do

It does not read, summarize, or judge the sources. That is Researcher's job.
This tool only fetches and ranks. Tokens spent: zero.
