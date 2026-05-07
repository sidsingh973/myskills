#!/bin/bash
set -e

REPO="https://github.com/sidsingh973/myskills"
RAW="https://raw.githubusercontent.com/sidsingh973/myskills/main"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

# Get list of skills from GitHub API
SKILLS=$(curl -s "https://api.github.com/repos/sidsingh973/myskills/contents" \
  | grep '"name"' | grep -v 'install.sh\|README' | sed 's/.*"name": "\(.*\)".*/\1/')

if [ -z "$SKILLS" ]; then
  echo "Could not fetch skill list. Check your internet connection."
  exit 1
fi

echo "Installing skills from $REPO"
echo ""

for skill in $SKILLS; do
  mkdir -p "$SKILLS_DIR/$skill"
  curl -fsSL "$RAW/$skill/SKILL.md" -o "$SKILLS_DIR/$skill/SKILL.md"
  echo "✓ $skill"
done

echo ""
echo "Done! Restart Claude Code to use the new skills."
