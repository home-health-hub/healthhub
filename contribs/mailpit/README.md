# contribs/mailpit

A disposable [Mailpit](https://mailpit.axllent.org/) SMTP server for testing
the built-in alert engine's Apprise-based email notifications
(`docs/Preliminary.md`) without sending real mail anywhere.

No auth is configured here — this is for local development and testing
only, not a stand-in for a production mail setup. If you want SMTP/UI
authentication on top of this, see
[bonelifer/mailpit-auth](https://github.com/bonelifer/mailpit-auth), which
manages a Mailpit password file and can wire itself into a compose file like
this one.

## Setup

```bash
docker compose up -d
```

- Web UI: http://127.0.0.1:8025
- SMTP: `127.0.0.1:1025`

Point the Hub's or a daemon's Apprise email URL at
`mailto://127.0.0.1:1025` (no credentials) and any mail sent will show up in
the web UI instead of a real inbox.
