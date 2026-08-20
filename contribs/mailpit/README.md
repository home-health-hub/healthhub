# contribs/mailpit

A disposable [Mailpit](https://mailpit.axllent.org/) SMTP server for testing
the built-in alert engine's Apprise-based email notifications
(`docs/Preliminary.md`) without sending real mail anywhere.

This is for local development and testing only, not a stand-in for a
production mail setup. The web UI, SMTP, and POP3 are all auth-gated
against a shared password file, managed by
[bonelifer/mailpit-auth](https://github.com/bonelifer/mailpit-auth) rather
than vendored into this repo — fetch the two scripts with `setup.sh` below.

## Setup

1. Fetch `mailpit-auth.py` and `set-bind-address.py` (re-run any time to
   pull the latest version):

   ```bash
   ./setup.sh
   ```

2. Add at least one user — this creates `data/passwords.txt` and, since the
   script sits next to `docker-compose.yml`, auto-detects it and wires its
   SMTP allowed-recipients list to match:

   ```bash
   ./mailpit-auth.py alice:hunter2
   ```

3. Start Mailpit:

   ```bash
   docker compose up -d
   ```

- Web UI: http://127.0.0.1:8025 (log in with the user/password from step 2)
- SMTP: `127.0.0.1:1025`

Point the Hub's or a daemon's Apprise email URL at
`mailto://alice:hunter2@127.0.0.1:1025` and any mail sent will show up in
the web UI instead of a real inbox.
