---
title: Health Hub
layout: default
---

# Health Hub

Health Hub brings the health devices you already use — a glucose meter, a
blood pressure cuff, a thermometer, a pulse oximeter ring, a smart scale —
into one place, on a computer in your own home. Each device keeps its own
program in charge of its own data — Health Hub just brings it all
together: one dashboard, one API, one MQTT feed, without keeping a second
copy of your data anywhere.

**Status: documentation only.** The [healthhub repository](https://github.com/home-health-hub/healthhub)
currently contains no code — it's the architecture and design specification
produced before implementation begins.

## Devices

Each device has its own standalone daemon — usable entirely on its own,
with or without Health Hub:

- **Glucose meter** (TrueMetrix) — [trividia-truemetrix-daemon](https://github.com/home-health-hub/trividia-truemetrix-daemon)
- **Pulse oximeter ring** (Viatom O2Ring) — [viatom-o2ring-daemon](https://github.com/home-health-hub/viatom-o2ring-daemon)
- **Smart scale** (Etekcity) — [etekcity-scale-daemon](https://github.com/home-health-hub/etekcity-scale-daemon)
- **Blood pressure monitor** (Etekcity) — [etekcity-bp-daemon](https://github.com/home-health-hub/etekcity-bp-daemon)
- **Thermometer** (standard Bluetooth Health Thermometer Profile) — [health-thermometer-daemon](https://github.com/home-health-hub/health-thermometer-daemon)
- **Basal body thermometer** (Easy@Home EBT-300) — [easyathome-bbt-daemon](https://github.com/home-health-hub/easyathome-bbt-daemon)

## Design documents

- [Preliminary Architecture and Design Specification](Preliminary.html) — governance and operations: administrator roles, permissions, backup, notifications, session/auth flow, and the core architectural principles.
- [Technical Design Specification](Claude-foundation.html) — the data model, profile/device handling, measurement semantics, dashboard, REST API, and MQTT/Home Assistant Discovery architecture.
- [Home Assistant MQTT Discovery Addendum](Claude-Addendum-HA.html) — the HA-specific subset of the MQTT design in more detail.
- [Branding](BRANDING.html) — pointer to the canonical [branding repository](https://github.com/home-health-hub/healthhub-branding).

## Elsewhere

- [Organization](https://github.com/home-health-hub) — every repository, including each daemon and its BLE/USB driver library.
- [Discussions](https://github.com/home-health-hub/healthhub/discussions) — questions, ideas, general chat.
