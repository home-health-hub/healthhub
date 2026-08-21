# Health Hub

<p align="center">
  <img src="docs/images/home-health-hub.png" alt="Health Hub logo" width="240">
</p>

![Documentation](https://img.shields.io/badge/project-documentation-168E98) ![Bluetooth LE](https://img.shields.io/badge/Bluetooth-LE-0082FC?logo=bluetooth&logoColor=white) ![USB HID](https://img.shields.io/badge/USB-HID-FF7A61?logo=usb&logoColor=white)

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue)](https://github.com/home-health-hub/healthhub/blob/main/LICENSE) [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/home-health-hub/healthhub#contributing) [![Discussions](https://img.shields.io/badge/discussions-welcome-blue)](https://github.com/home-health-hub/healthhub/discussions)

Preliminary architecture and design documentation for Health Hub — a personal/household health-data appliance that provides a unified Web UI, API, and MQTT interface around a set of independent health-device daemons, without replacing those daemons as the authoritative source of their own device data.

**Status: documentation only.** This repository currently contains no code — it's the architecture and design specification produced before implementation begins.

## Related daemons

Health Hub aggregates data from these independently-usable device daemons:

- [trividia-truemetrix-daemon](https://github.com/home-health-hub/trividia-truemetrix-daemon) — TrueMetrix glucose meter
- [viatom-o2ring-daemon](https://github.com/home-health-hub/viatom-o2ring-daemon) — Viatom O2Ring pulse oximeter
- [etekcity-scale-daemon](https://github.com/home-health-hub/etekcity-scale-daemon) — Etekcity smart scale
- [etekcity-bp-daemon](https://github.com/home-health-hub/etekcity-bp-daemon) — Etekcity blood pressure monitor
- [health-thermometer-daemon](https://github.com/home-health-hub/health-thermometer-daemon) — standard Bluetooth Health Thermometer Profile devices
- [easyathome-bbt-daemon](https://github.com/home-health-hub/easyathome-bbt-daemon) — Easy@Home EBT-300 basal body thermometer

Each daemon remains fully usable on its own — installing Health Hub is never a prerequisite for using any of them individually.

## Documentation

Also browsable as a website: **[home-health-hub.github.io/healthhub](https://home-health-hub.github.io/healthhub/)**.

- [`docs/BRANDING.md`](docs/BRANDING.md) — Shared visual language, palette, README banner rules, and current daemon artwork.
- [`docs/Preliminary.md`](docs/Preliminary.md) — Preliminary Architecture and Design Specification: governance and operations (administrator roles, permissions, backup, notifications, session/auth flow, software lifecycle) plus the core architectural principles.
- [`docs/Claude-foundation.md`](docs/Claude-foundation.md) — Health Hub Technical Design Specification: the data model, profile/device handling, measurement semantics, dashboard, REST API, and MQTT/Home Assistant Discovery architecture.
- [`docs/Claude-Addendum-HA.md`](docs/Claude-Addendum-HA.md) — Home Assistant MQTT Discovery Addendum: the HA-specific subset of the MQTT design in more detail.
- [`docs/HEALTH_HUB_BBT_DAEMON_ADDENDUM.md`](docs/HEALTH_HUB_BBT_DAEMON_ADDENDUM.md) — BBT Daemon Addendum: architecture and requirements for the basal body temperature daemon. Copy — maintained in [easyathome-bbt-daemon](https://github.com/home-health-hub/easyathome-bbt-daemon).
- [`docs/BRANDING_SYNC_AUTOMATION.md`](docs/BRANDING_SYNC_AUTOMATION.md) — **Design proposal, not yet implemented.** A CI workflow to keep each daemon's branding assets in sync with the canonical branding repo automatically, with a human merge gate on every visual change.

## Contribs

[`contribs/`](contribs/) — reference `docker-compose` stacks (a Mosquitto
broker pre-configured with the §26.2 publish-rights ACL model, and a Mailpit
SMTP server) for exercising the designs above locally. Not part of Health
Hub itself.

## Acknowledgments

- Architecture review, documentation synthesis, and related daemon code review assisted by [Claude](https://www.anthropic.com/claude).
- Branding development, documentation, and repository maintenance assisted by [OpenAI Codex](https://openai.com/codex/).

## Contributing

Contributions are welcome!

- **Bug reports**: [Open an issue](https://github.com/home-health-hub/healthhub/issues).
- **Everything else** (questions, feature requests, ideas, general discussion): [Use Discussions](https://github.com/home-health-hub/healthhub/discussions).
- Pull requests are welcome for bug fixes or discussed features.

## License

This project is licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) for more information.
