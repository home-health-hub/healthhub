# contribs/mosquitto

A local [Eclipse Mosquitto](https://mosquitto.org/) broker, pre-configured to
enforce the publish-rights model from
[`docs/Claude-foundation.md` §26.2](../../docs/Claude-foundation.md#262-publish-rights-are-restricted-to-daemons-and-the-hub):
each device daemon may publish only to its own raw topic tree
(`<topic_prefix>/#`), the Hub may publish only to its own normalized tree
(`healthhub/#`), and every other client is subscribe-only.

This is for local development and testing — it is not a production-hardened
broker deployment.

## Setup

1. Create the password file (one call per credential, `-b` adds without
   prompting):

   ```bash
   mosquitto_passwd -c -b config/passwd trividia-truemetrix-daemon <password>
   mosquitto_passwd -b config/passwd viatom-o2ring-daemon <password>
   mosquitto_passwd -b config/passwd etekcity-scale-daemon <password>
   mosquitto_passwd -b config/passwd etekcity-bp-daemon <password>
   mosquitto_passwd -b config/passwd health-thermometer-daemon <password>
   mosquitto_passwd -b config/passwd healthhub <password>
   ```

   `config/passwd` is gitignored — it holds real credentials, not just an
   example.

2. Edit `config/acl.conf` if your usernames differ, or to add/remove
   daemons.

3. Start the broker:

   ```bash
   docker compose up -d
   ```

The broker listens on `127.0.0.1:1883`. Point each daemon's `[mqtt]` config
and the Hub's MQTT client at that address with the matching username/password.
