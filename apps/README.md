# Dobey App Knowledge Base

App-specific knowledge files for [dobeypilot](../dobeypilot/SKILL.md) — each file tells the AI exactly how to control that app without trial and error.

## How it works

When dobeypilot encounters an app it hasn't seen before, it checks:
1. Local cache (`~/.dobey/contexts/<AppName>.json`) — fastest
2. This GitHub library — pulls and caches locally for future sessions
3. If neither exists — indexes the app live and saves back to both

## Adding a new app

After dobeypilot figures out a new app, it saves the workflow here as `apps/<AppName>.json`. You can also contribute manually.

## Apps

| App | Platform | Notes |
|-----|----------|-------|
| [HEC-HMS](HEC-HMS.json) | macOS | USACE hydrologic modeling. Java Swing — uses AX index for buttons, AppleScript for text input. |

## JSON schema

```json
{
  "description": "One-line description",
  "app_ax_name": "Exact name as seen by macOS Accessibility API",
  "platform": "macOS | Windows | cross-platform",
  "menus": ["File", "Edit", "..."],
  "ax_notes": "Quirks specific to this app's AX exposure",
  "workflows": [
    {
      "name": "Workflow name",
      "verified": "YYYY-MM-DD",
      "steps": ["1. ...", "2. ..."],
      "button_map": {},
      "field_map": {}
    }
  ]
}
```
