#!/bin/sh
set -e  # Exit on any error

# Always run from the repo root (so paths resolve reliably)
cd "$(dirname "$0")/.."

# Files to combine
FILES=".github/templates/readme-header.md .github/templates/usage.md"

# Verify that all required files exist
for f in $FILES; do
  if [ ! -f "$f" ]; then
    echo "❌ Missing required file: $f" >&2
    exit 1
  fi
done

# Build new README in a temp file
tmpfile="$(mktemp)"
{
  echo "<!-- This README is generated. Do not edit directly. -->"
  for f in $FILES; do
    cat "$f"
  done
} > "$tmpfile"

# Only overwrite & stage if content changed
if ! cmp -s "$tmpfile" README.md; then
  mv "$tmpfile" README.md
  git add README.md
  echo "✅ README.md updated and staged."
else
  rm "$tmpfile"
  echo "ℹ️  No changes to README.md."
fi
