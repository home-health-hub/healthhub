#!/usr/bin/bash
# Fetches bonelifer/mailpit-auth into ./mailpit-auth/ so its tools (auth-file
# management, bind-address switching) can manage this folder's
# docker-compose.yml. Not vendored directly in this repo so there's a single
# source of truth. Safe to re-run: pulls the latest instead of re-cloning.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/bonelifer/mailpit-auth.git"
DEST_DIR="$SCRIPT_DIR/mailpit-auth"

if [ -d "$DEST_DIR/.git" ]; then
    git -C "$DEST_DIR" pull --ff-only
else
    git clone "$REPO_URL" "$DEST_DIR"
fi

echo "mailpit-auth is ready in $DEST_DIR"
echo
echo "Add a user and wire up the SMTP allowed-recipients list, run from"
echo "this directory ($SCRIPT_DIR):"
echo "  ./mailpit-auth/mailpit-auth.py -y ./docker-compose.yml <user>:<password>"
