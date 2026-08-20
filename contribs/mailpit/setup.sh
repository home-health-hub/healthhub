#!/usr/bin/bash
# Fetches just the two scripts this folder needs from bonelifer/mailpit-auth
# (not the whole repo, so its README.md/LICENSE/etc. don't land here too).
# Not vendored directly in this repo so there's a single source of truth.
# Safe to re-run: overwrites with the latest version each time.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAW_BASE="https://raw.githubusercontent.com/bonelifer/mailpit-auth/main"

for f in mailpit-auth.py set-bind-address.py; do
    curl -fsSL "$RAW_BASE/$f" -o "$SCRIPT_DIR/$f"
    chmod +x "$SCRIPT_DIR/$f"
done

echo "Fetched mailpit-auth.py and set-bind-address.py into $SCRIPT_DIR"
echo
echo "Add a user and wire up the SMTP allowed-recipients list, run from"
echo "this directory ($SCRIPT_DIR):"
echo "  ./mailpit-auth.py <user>:<password>"
