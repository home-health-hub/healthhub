# Contribs

Reference `docker-compose` stacks for standing up supporting services locally
while developing or testing Health Hub. These are not part of Health Hub
itself and aren't required to use any of the daemons or the Hub — they're
here purely to make it easy to exercise the designs described in
[`docs/Claude-foundation.md`](../docs/Claude-foundation.md) and
[`docs/Preliminary.md`](../docs/Preliminary.md) without needing a real SMTP
server or a production MQTT broker.

- [`mosquitto/`](mosquitto/) — an MQTT broker pre-configured with the
  publish-rights ACL model from §26.2 (daemons and the Hub can publish only
  to their own topics; everything else is subscribe-only).
- [`mailpit/`](mailpit/) — a disposable SMTP server for testing the
  Apprise-based alert engine's email notifications without sending real mail.

Each subfolder is a standalone `docker-compose` project — copy the one you
need, or run it in place.
