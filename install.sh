#!/usr/bin/env bash
# Install claude-config into a target project's .claude directory.
# Usage: ./install.sh /path/to/target-project
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <target-project-path>" >&2
  exit 1
fi

SRC="$(cd "$(dirname "$0")" && pwd)"
TARGET="$1"

if [ ! -d "$TARGET" ]; then
  echo "Error: target project '$TARGET' does not exist" >&2
  exit 1
fi

DEST="$TARGET/.claude"
mkdir -p "$DEST"

for dir in skills output-styles scripts; do
  cp -R "$SRC/$dir" "$DEST/"
  echo "Copied $dir -> $DEST/$dir"
done

echo "Done."
