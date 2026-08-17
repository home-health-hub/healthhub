# Health Hub Technical Design Specification

## 1. Purpose

The Health Hub will provide a unified interface to multiple independent health-device daemons.

The initial device daemons are:

* TrueMetrix glucose daemon
* Viatom O2Ring daemon
* Etekcity scale daemon
* Etekcity blood-pressure daemon

The Health Hub is **not intended to replace these daemons**.

Installing the Health Hub must not be a prerequisite for using any daemon individually. A person may install and use, for example, only the O2Ring daemon — its device driver, automatic acquisition, long-term SQLite storage, PDF reports, and API — without installing Health Hub at all. The Health Hub depends on supported daemon APIs; supported daemons must not depend on the Health Hub.

The existing daemons remain responsible for:

* Communicating with their physical devices.
* Device-specific protocols.
* Device pairing and connection.
* Device-specific functionality.
* Profiles and device assignments where supported.
* Recording measurements.
* Maintaining detailed historical records.
* Generating detailed reports and PDFs.

The Health Hub provides a higher-level aggregation layer for:

* Current health information.
* Recent measurements.
* Device status.
* Profile/device overview.
* O2Ring session summaries.
* Basic trends.
* A local dashboard for a small HDMI display.
* MQTT integration with external systems.
* Home Assistant MQTT Discovery.
* A unified API for other applications.

The Health Hub should make the four existing systems feel like one coherent system without taking ownership of their device-specific responsibilities.

---

# 2. Architectural Overview

```text
                         ┌─────────────────────────┐
                         │       Health Hub        │
                         │                         │
                         │  Aggregation / API      │
                         │  Current state          │
                         │  Recent data            │
                         │  Trends                 │
                         │  Device status          │
                         │  MQTT                   │
                         │  Dashboard               │
                         └───────────┬─────────────┘
                                     │
                     ┌───────────────┼───────────────┐
                     │               │               │
                     ▼               ▼               ▼
                TrueMetrix        O2Ring         Etekcity
                  daemon          daemon          daemons
                     │               │               │
                     └───────────────┴───────────────┘
                                     │
                              Physical devices
```

The Health Hub should consume the existing daemon APIs rather than directly accessing their databases.

This preserves clear ownership of historical data.

All components — daemons, Health Hub, and dashboard — normally run on the same physical machine, closer to a personal NAS appliance than a distributed system. This means daemon discovery, remote registration, and WAN-facing authentication are not architectural requirements: the Hub already knows what daemons are installed locally. The daemon API remains the correct boundary between Health Hub and each daemon even so — it keeps the Hub from depending on daemon internals — but its transport can be as simple as a local Unix socket or a localhost-only HTTP interface, since it never needs to be exposed over a network.

---

# 3. Core Architectural Principle

The fundamental division of responsibility is:

> **Device daemons collect and preserve detailed device data. The Health Hub aggregates and presents that data.**

Therefore:

```text
Physical device
      ↓
Device daemon
      ↓
Detailed historical record
      ↓
Device-specific report/PDF
```

while:

```text
Device daemon
      ↓
Health Hub
      ↓
Current/recent overview
      ↓
Dashboard / REST / MQTT
```

The Health Hub should not become a fifth device daemon or unnecessarily duplicate the complete historical databases maintained by the existing daemons.

---

# 4. Device Daemon Responsibilities

Each daemon remains authoritative for its own device.

Responsibilities include:

* Hardware communication.
* Device discovery.
* Device connection.
* Device-specific configuration.
* Device identification.
* Device-specific measurement handling.
* Recording measurements.
* Maintaining detailed historical records.
* Device-specific reports.
* PDF generation.
* Existing device-specific operating modes.

The Health Hub must not remove or restrict existing daemon functionality merely to make the devices appear more uniform.

---

# 5. Health Hub Responsibilities

The Health Hub is responsible for aggregation and presentation.

Responsibilities include:

* Communicating with the device daemons.
* Maintaining a unified view of profiles and devices.
* Retrieving current and recent measurements.
* Normalizing common metadata.
* Tracking measurement freshness.
* Tracking device availability.
* Producing summaries.
* Producing basic descriptive trends.
* Providing a unified REST API.
* Publishing normalized MQTT information.
* Publishing Home Assistant MQTT Discovery information.
* Providing information to the local dashboard.

---

# 6. Profiles and Physical Devices

Profiles represent people.

Physical devices are separate entities associated with profiles.

The architecture must support:

```text
Profile
└── Active physical device
```

as well as device replacement:

```text
Profile
├── Old physical device
└── Current physical device
```

Multiple people can use the same Health Hub, with each person having their own assigned devices.

For example:

```text
Profiles
├── William
│   └── O2Ring A
│
└── Person B
    └── O2Ring B
```

A physical device should be assigned to one profile at a time.

The profile identity must not be tied permanently to the physical device's MAC address or other hardware identifier.

---

# 7. O2Ring Profile Handling

The O2Ring daemon should support the same general profile/device concept required by the Health Hub.

This is an intentional design decision.

### Decision

Add full profile support to the O2Ring daemon.

### Reason

The original O2Ring implementation may appear to work without profiles when there is only one person using one ring.

However, the Health Hub is intended to support multiple people and multiple physical devices.

A physical O2Ring therefore cannot serve as a sufficient substitute for a user identity.

The architecture must allow:

```text
William
└── O2Ring A

Person B
└── O2Ring B
```

while also supporting replacement:

```text
William
├── O2Ring A   ← replaced
└── O2Ring C   ← current
```

Historical measurements remain associated with the physical device that actually produced them.

### Important rationale

The purpose of profiles is **not** to encourage sharing one O2Ring between people.

The primary purpose is:

* Supporting multiple people on one Hub.
* Maintaining persistent user identity.
* Supporting device replacement.
* Keeping O2Ring consistent with the overall Health Hub profile/device model.

This rationale should be retained in the final implementation documentation so future code changes do not remove profile support in an attempt to simplify the design.

---

# 8. Device Replacement

Device replacement must not create a new person/profile.

For example:

```text
William
├── O2Ring A
│   └── Historical measurements
│
└── O2Ring B
    └── Current measurements
```

The physical-device identifier may change.

The profile does not.

Historical records retain their original physical-device association.

The same general principle should apply to the other device types.

---

# 9. Measurement Metadata

Where practical, measurements from all daemons should expose common metadata.

Conceptually:

```text
Measurement
├── profile
├── device
├── measurement_type
├── measured_at
├── received_at
└── value(s)
```

The actual measurement payload remains device-specific.

For example:

```text
Blood Pressure
├── systolic
├── diastolic
└── pulse
```

while:

```text
O2Ring
├── SpO2
└── pulse
```

The surrounding metadata should be normalized without forcing the actual measurements into an artificial common structure.

---

# 10. Measurement Time

The system must distinguish between:

```text
measured_at
received_at
```

`measured_at` represents when the physical measurement actually occurred.

`received_at` represents when the daemon or Health Hub received/synchronized it.

These timestamps can differ significantly.

For example:

```text
Measured:
Aug 14, 10:18 PM

Received:
Aug 15, 12:32 AM
```

The user-facing display should use `measured_at` when describing when a measurement occurred.

---

# 11. Human-Readable Dates and Times

Relative elapsed time alone must not be used for health measurements when it could be ambiguous.

Avoid displaying only:

```text
Glucose: 95 — 2h 14m ago
```

because the measurement could have occurred on a different calendar day.

Prefer:

```text
Glucose
95 mg/dL
Today 10:18 PM
```

or:

```text
Glucose
95 mg/dL
Yesterday 10:18 PM
```

or:

```text
Glucose
95 mg/dL
Aug 12, 10:18 PM
```

Display rules:

* Current local calendar day → `Today`
* Previous local calendar day → `Yesterday`
* Older measurements → calendar date
* Relative age may optionally be displayed in addition to the absolute date/time.

The actual timestamp remains authoritative.

---

# 12. Data Freshness

Device availability and measurement freshness are separate concepts.

A device can be connected while its latest measurement is several hours old.

For example:

```text
Device:
Connected

Latest glucose:
95 mg/dL
Yesterday 10:18 PM
```

The Health Hub should therefore track:

```text
Device status
Measurement freshness
```

Possible measurement states include:

* Current
* Recent
* Stale
* No data available

Thresholds may vary according to measurement type.

---

# 13. Device-Specific Functionality

Device-specific functionality should remain device-specific.

**Existing supported operating modes must not be removed merely to normalize the daemons.**

The Health Hub should consume the capabilities actually provided by each daemon.

For example, the Etekcity scale must continue to support **weight-only operation**.

The Health Hub must not require impedance or body-composition information.

Conceptually:

```text
Scale
├── Weight-only mode
└── Weight + impedance/body composition
```

If only weight is available:

```text
Weight
298.4 lb
```

is a completely valid result.

If additional body-composition information is available, it can also be presented.

The presence or absence of optional capabilities must not make the basic device functionality invalid.

---

# 14. O2Ring Measurement Model

The O2Ring has two fundamentally different measurement modes:

1. Spot/one-shot measurements.
2. Continuous/live sessions.

These should remain distinct.

---

## 14.1 Spot Measurement

A spot measurement is a point-in-time observation.

Conceptually:

```text
O2Ring
├── Profile
├── Device
├── Type: spot
├── Measured at
├── SpO2
└── Pulse
```

---

## 14.2 Continuous Session

A continuous session represents a time series.

Conceptually:

```text
O2Ring Session
├── Profile
├── Device
├── Started at
├── Ended at
├── Duration
├── Summary
└── Samples
```

The complete session data remains under the control of the O2Ring daemon.

The Health Hub does not need to duplicate every raw sample.

The Health Hub can consume a session summary containing information such as:

* Start time.
* End time.
* Duration.
* Average SpO2.
* Minimum SpO2.
* Maximum SpO2.
* Average pulse.
* Minimum pulse.
* Maximum pulse.
* Sample count.

---

# 15. O2Ring Dashboard Presentation

Live and completed-session information should be presented differently.

Example live display:

```text
O2RING

97% SpO2
62 BPM

LIVE
00:18:42
```

Example completed-session display:

```text
LAST O2RING SESSION

Aug 14, 11:12 PM
to
Aug 15, 7:03 AM

Duration       7h 51m
Average SpO2   96%
Lowest SpO2    89%
Average Pulse  61 BPM
```

The detailed O2Ring history and reports remain the responsibility of the O2Ring daemon.

---

# 16. Historical Data and Doctor Reports

The four device daemons are primarily intended to maintain historical health data and produce detailed reports/PDFs that can be used when discussing information with healthcare providers.

The Health Hub should not replace that functionality.

The device daemon remains the authoritative source for detailed historical information.

The Health Hub provides a convenient unified overview and should not attempt to become another complete medical-record system.

---

# 17. Current Status

The primary Health Hub dashboard should provide a unified current view.

For example:

```text
HEALTH HUB

O2       97%      62 BPM
BP       124/78   68 BPM
Glucose  95 mg/dL
Weight   298.4 lb

O2Ring       Connected
BP Monitor   Available
Scale        Available
Glucose      Last sync
```

Measurements should include appropriate timestamps whenever it is possible that the value is not current.

---

# 18. Recent Measurements

A recent-measurements view should present information chronologically.

Example:

```text
RECENT

Glucose
95 mg/dL
Today 10:18 PM

Blood Pressure
124/78
Today 9:15 PM

O2
97% / 62 BPM
Today 9:03 PM

Weight
298.4 lb
Today 7:55 AM
```

The exact presentation should be optimized for the small display.

---

# 19. Trends

The Health Hub should provide basic descriptive trends.

Potential trends include:

* Weight.
* Blood pressure.
* Glucose.
* Pulse.
* O2Ring session summaries.

Possible calculations include:

* Average.
* Minimum.
* Maximum.
* Change from previous period.
* Change from previous measurement.
* Trend direction.

The Hub should remain descriptive rather than attempting to provide medical diagnoses: it should describe trends in the data ("your average systolic value increased compared with the previous period") rather than medical conclusions ("your blood pressure is dangerous"). Users may define personal, non-medical targets (for example a weight goal) and see progress toward them; this is distinct from medical advice.

---

# 20. "What Changed?" View

A future feature could compare the current period with a previous period.

For example:

```text
WHAT CHANGED?

Weight
298.4 lb
+2.1 lb from previous week

Average BP
122/77
-4/-2 from previous week

Average glucose
101 mg/dL
+6 mg/dL from previous week

O2 sessions
18
```

This is intended to make changes easier to see, not to provide medical interpretation.

---

# 21. Physical Display

The initial display is a **5-inch HDMI display connected to an older business thin-client PC**.

The HDMI display itself does not require independent processing.

The thin client runs:

* Linux.
* Device daemons.
* Health Hub.
* Dashboard.

Conceptually:

```text
Linux thin-client PC
│
├── Device daemons
├── Health Hub
└── Dashboard
       │
       ▼
     HDMI
       │
       ▼
    5" display
```

A local web dashboard displayed in kiosk mode is a suitable architectural approach.

The dashboard should remain independent from the device-daemon implementations.

---

# 22. Dashboard Screens

Potential dashboard views include:

### Overview

Current readings and device status.

### Vitals

Blood pressure, glucose, O2, and pulse.

### Body

Weight and available body-composition information.

### O2Ring

Live O2 information or the most recent completed session.

### Trends

Graphs and descriptive trends.

### Devices

Connection and device status.

The small display means information should be divided into focused screens rather than attempting to display everything simultaneously.

---

# 23. Automatic Screen Rotation

Automatic rotation may be useful for a permanently mounted display.

For example:

```text
Overview
   ↓
Vitals
   ↓
O2Ring
   ↓
Body
   ↓
Trends
   ↓
Overview
```

The rotation interval should be configurable.

Automatic rotation should be disableable.

---

# 24. Night Mode

Because the display may be used overnight, the dashboard should support:

* Reduced brightness.
* Configurable night hours.
* Screen blanking.
* Optional wake behavior.
* Reduced visual activity.

The display should not become an unnecessary light source during overnight O2Ring use.

---

# 25. MQTT

MQTT is an important external integration interface.

Its purpose is not only communication within the Health Hub infrastructure.

The goal is to make Health Hub information available to people and systems that are **not using the Hub's own infrastructure**, including:

* Home Assistant.
* Node-RED.
* openHAB.
* Other MQTT-aware automation systems.
* Custom applications.
* Scripts.

The Health Hub should therefore publish a clean, normalized MQTT interface.

**Revised (post code-review):** MQTT is also used as the Hub's own near-real-time input channel from the daemons, not only as an output interface to external consumers. Source review of all four existing daemons found that each already implements an off-by-default MQTT publish that fires on every new reading (`<topic_prefix>/<device_id>/state`), independent of whether anything is subscribed. The Hub subscribes to this existing feed as its push mechanism instead of polling each daemon's REST API on an interval, and instead of adding a new bespoke webhook to every daemon. This is a separate MQTT usage from the Hub's own outbound normalized/HA-Discovery topics described below — a daemon's raw per-device topic is not the same stream as the Hub's normalized `healthhub/<profile>/...` output.

---

# 26. MQTT Architecture

The overall architecture is:

```text
Device Daemons
      │
      ├── MQTT (raw, per-daemon, already exists) ──┐
      │                                              ▼
      └── API (on-demand: query/config/reports) → Health Hub
                                                       │
                                                       └── MQTT (normalized, Hub-published)
                                                            │
                                                            ├── Home Assistant
                                                            ├── Node-RED
                                                            ├── openHAB
                                                            ├── Custom applications
                                                            └── Other MQTT consumers
```

The Health Hub should not require external consumers to understand the internal APIs or database structures of the individual daemons. Likewise, a daemon's own raw MQTT publish requires no knowledge of the Hub or Home Assistant — it publishes unconditionally, and the Hub is simply one possible subscriber.

## 26.1 Raw Daemon Feed vs. Hub Normalized Feed

Both feeds are available to any MQTT consumer, including consumers outside the Hub's own infrastructure. Documentation for administrators/integrators should make both paths explicit rather than only documenting the Hub's output.

### Getting the raw daemon feed

1. Enable `[mqtt] enabled = yes` in the specific daemon's own config file (off by default).
2. Subscribe to that daemon's topic directly: `<topic_prefix>/<device_id-or-address>/state`.
3. The payload is that daemon's native reading shape — its own field names and units, unmodified. It is keyed by physical device identifier, not by person.

For daemons where a reading is tagged to a profile only after the fact through a human confirmation step (the Etekcity scale and blood-pressure daemons — see Sections 6–8), the raw MQTT publish fires at storage time, which can be *before* that confirmation happens. A raw-feed subscriber may therefore see a reading with no resolved profile yet.

### Getting the Hub's normalized feed

1. Subscribe to the Hub's own topics: `healthhub/<profile>/<measurement_type>/...` (Section 27).
2. Optionally use Home Assistant MQTT Discovery (Section 30) instead of subscribing to raw topics at all.
3. The payload uses the Hub's common metadata shape (Section 28): profile, device, `measured_at`/`received_at`, availability/freshness — consistent across every device type, not just the four current daemons.

### Why choose one over the other

| | Raw daemon feed | Hub normalized feed |
|---|---|---|
| Identity | Physical device (address/ID) | Person (profile) |
| Shape | Native per-daemon fields/units | Consistent across all device types |
| Latency | Lowest — no extra hop | One hop through the Hub |
| Availability | Works even if the Hub is never installed | Requires the Hub to be running |
| Profile resolution | May be unresolved at publish time (scale/BP) | Hub is responsible for resolving/reconciling before publishing |
| Home Assistant Discovery | Not provided | Provided |
| Best for | Single-device automations, debugging exactly what a daemon produced, single-person households where device identity already is person identity | Multi-person households, dashboards/automations that shouldn't care which physical daemon produced a value, anything wanting consistent freshness/availability semantics |

How the Hub reconciles a raw reading that arrives with no profile yet (for the scale/BP case above) — wait for the assignment, poll the daemon's API once assignment completes, or something else — is not yet settled and should be resolved during Hub implementation, not assumed here.

## 26.2 Publish Rights Are Restricted to Daemons and the Hub

Only a device daemon (on its own raw topics) and the Health Hub (on its own normalized topics) may publish. Every other MQTT client — Home Assistant, Node-RED, openHAB, custom applications/scripts, dashboards, anything else on the broker — is subscribe-only.

```text
Device Daemon   → publish (its own raw topics only)
Health Hub      → publish (its own normalized topics only) + subscribe (daemon raw topics)
Everyone else   → subscribe only
```

This should be enforced by the broker's own access control (per-client credentials with topic-scoped publish ACLs), not merely by convention, since a client that *can* publish into `healthhub/...` or a daemon's topic could otherwise inject fabricated readings or spoof availability/state. None of the entities currently described in this document (Sections 30–39) are actuators — Health Hub sensor data has no legitimate reason for an external consumer to publish back into it, so a strict subscribe-only default for external clients has no functional downside today. If a future device or feature genuinely needs a command/actuator topic, that would need its own explicitly-scoped write permission rather than a broad relaxation of this rule.

---

# 27. MQTT Topic Design

The normal Health Hub MQTT topics should use a project-specific namespace.

For example:

```text
healthhub/william/o2/spo2
healthhub/william/o2/pulse

healthhub/william/bp/systolic
healthhub/william/bp/diastolic
healthhub/william/bp/pulse

healthhub/william/glucose
healthhub/william/weight
```

The exact topic hierarchy should be finalized during implementation.

The topics must remain useful to generic MQTT consumers.

They must not be designed solely around Home Assistant.

---

# 28. MQTT Data Model

The Health Hub should provide normalized metadata around device-specific measurements.

Conceptually:

```json
{
    "profile": "william",
    "device": "o2ring-01",
    "measured_at": "2026-08-15T00:12:34Z",
    "received_at": "2026-08-15T00:12:35Z",
    "measurement": {
        "spo2": 97,
        "pulse": 62
    }
}
```

The exact schema and topic structure will be finalized during implementation.

The common model should support:

* Profile.
* Device.
* Measurement type.
* Measurement timestamp.
* Reception timestamp.
* Value.
* Unit.
* Availability/status.

---

# 29. MQTT and O2Ring Sessions

O2Ring live readings and completed sessions should be handled differently.

Live data can be published as current state.

A completed session can publish a summary.

The Health Hub should not automatically publish thousands of raw session samples as individual MQTT entities.

Conceptually:

```text
O2Ring live
    ↓
Current measurement topic

O2Ring session completed
    ↓
Session summary topic
```

Detailed raw session data remains available through the O2Ring daemon.

---

# 30. Home Assistant MQTT Discovery

Home Assistant MQTT Discovery will be an optional MQTT integration feature.

The Health Hub will publish:

1. Normal Health Hub MQTT data.
2. Home Assistant Discovery configuration.

Home Assistant receives the discovery configuration and automatically creates entities.

```text
Health Hub
    │
    │ Discovery configuration
    ▼
MQTT Broker
    │
    ▼
Home Assistant
```

Discovery tells Home Assistant what an entity is.

Normal MQTT state messages provide the actual values.

---

# 31. Home Assistant Device Organization

The Health Hub should use Home Assistant's device/entity model to keep related measurements organized.

Conceptually:

```text
Health Hub
└── William
    ├── O2Ring
    │   ├── SpO2
    │   └── Pulse
    │
    ├── Blood Pressure
    │   ├── Systolic
    │   ├── Diastolic
    │   └── Pulse
    │
    ├── Scale
    │   └── Weight
    │
    └── Glucose
        └── Glucose
```

The exact Home Assistant entity structure should be finalized during implementation.

---

# 32. Home Assistant and Profiles

Profiles are important to MQTT Discovery because multiple people may use the same Hub.

For example:

```text
William
└── O2Ring A

Person B
└── O2Ring B
```

Home Assistant should distinguish:

```text
William O2 SpO2
Person B O2 SpO2
```

rather than creating ambiguous generic entities.

The logical profile identity should remain independent of the physical device identifier.

---

# 33. Home Assistant and Device Replacement

A physical device replacement should not unnecessarily create a new logical Home Assistant entity.

For example:

```text
William
├── O2Ring A
│   └── Historical data
│
└── O2Ring B
    └── Current device
```

The logical Health Hub/profile entity should remain stable where appropriate.

The underlying physical device may change.

---

# 34. Home Assistant and the O2Ring

Potential O2Ring entities include:

```text
William O2 SpO2
William O2 Pulse
William O2 Last Session Average SpO2
William O2 Last Session Minimum SpO2
William O2 Last Session Duration
```

The Hub should not create an entity for every raw O2Ring session sample.

Detailed session information remains available from the O2Ring daemon.

---

# 35. Home Assistant and the Scale

Weight-only operation must remain fully supported.

If the scale provides only weight:

```text
William Weight
```

is sufficient.

If additional measurements are available, corresponding entities may be created.

For example:

```text
William Weight
William Body Fat
William Muscle Mass
William Body Water
```

The Health Hub must never require impedance/body-composition data simply because Home Assistant Discovery supports additional entities.

---

# 36. Home Assistant Independence

Home Assistant must not become a dependency of the Health Hub.

The architecture should be:

```text
Health Hub
    │
    └── MQTT integration
         │
         ├── Generic MQTT data
         │
         └── Home Assistant Discovery
```

Home Assistant is one consumer of the Health Hub.

The MQTT interface should remain useful without Home Assistant.

---

# 37. Discovery Generation

Home Assistant Discovery information should be generated from the Health Hub's actual:

* Profiles.
* Devices.
* Capabilities.
* Measurement types.

The Hub must not assume that every device supports every measurement.

For example:

```text
Scale
└── Weight only
```

should result in a weight entity only.

A scale providing additional measurements may expose additional entities.

The same principle applies to all future device integrations.

---

# 38. Availability

The Health Hub should provide MQTT availability information.

The system should distinguish between:

```text
Health Hub unavailable
```

```text
Health Hub available
Device unavailable
```

and:

```text
Health Hub available
Device available
No recent measurement
```

These are different states and should not be collapsed into one status.

---

# 39. Retained MQTT State

Current Health Hub state should use retained MQTT messages where appropriate.

This allows MQTT consumers to recover the latest known state after restarting without waiting for a new physical measurement.

Discovery configuration should also be retained as appropriate for Home Assistant MQTT Discovery.

---

# 40. REST API

The Health Hub should provide a unified API for its dashboard and future consumers.

A possible initial structure is:

```text
/api/v1/status
/api/v1/profiles
/api/v1/devices
/api/v1/current
/api/v1/recent
/api/v1/trends
/api/v1/o2/sessions
```

The exact API structure should be finalized before implementation.

The dashboard should use the Health Hub API rather than directly communicating with each device daemon.

Each of the four existing daemon APIs is now versioned under `/api/v1/` and exposes a `GET /api/v1/capabilities` endpoint describing its measurement types, measurement modes, profile model, timestamp semantics, and MQTT availability. The Hub should use this endpoint to configure itself per daemon (which measurements exist, whether to subscribe to that daemon's MQTT feed, how to interpret its timestamps) rather than hardcoding assumptions about any specific daemon.

The API must not create a second permission system: it should expose the same authorization model used elsewhere in the Hub, so a `curl`/script client cannot bypass restrictions that would apply through another interface. Scoped, individually revocable API credentials may be issued for automation (for example, a read-only credential for a personal export script) without affecting the owner's normal login credentials.

---

# 41. Data Quality

The Health Hub should preserve relevant data-quality/status information provided by the source daemons.

The dashboard should not present stale or unavailable information as though it were current.

For example:

```text
Glucose
95 mg/dL
Yesterday 10:18 PM
Stale
```

is preferable to simply:

```text
Glucose
95 mg/dL
```

when the value is old.

---

# 42. Units

The Health Hub should support consistent user-selected units where applicable.

Examples:

```text
Weight:
lb / kg

Glucose:
mg/dL / mmol/L

Temperature:
°F / °C
```

Unit preferences should be configurable.

Conversions must preserve adequate precision and must not alter the meaning of historical records.

---

# 43. Configuration

Health Hub configuration should contain its own settings, including:

* Device daemon endpoints.
* MQTT broker configuration.
* Profile preferences.
* Dashboard configuration.
* Display rotation.
* Night mode.
* Unit preferences.
* Trend settings.
* Optional thresholds.
* Home Assistant Discovery configuration.

Device-specific configuration should remain with the appropriate device daemon.

---

# 44. Security

The Health Hub handles personal health information.

Security must therefore be considered from the beginning.

Areas include:

* API exposure.
* MQTT authentication.
* MQTT broker ACLs restricting publish rights to daemons (their own topics) and the Hub (its own topics); every other MQTT client is subscribe-only (Section 26.2).
* MQTT TLS where appropriate.
* Remote API authentication where appropriate.
* File permissions.
* Database permissions.
* Avoiding sensitive health information in logs.
* Restricting unnecessary network exposure.
* Audit logging of security-sensitive administrative and API actions, so that script/`curl` access does not become an unaudited side channel.

The default configuration should avoid unnecessarily exposing health information.

---

# 45. Extensibility

The Hub should allow additional device daemons to be integrated later.

Potential future devices could include:

* Thermometers.
* Additional pulse oximeters.
* Continuous glucose monitors.
* Additional blood-pressure monitors.
* Additional scales.

New integrations should ideally require adding an adapter/interface rather than redesigning the Health Hub.

---

# 46. What Should Be Normalized

The following should be normalized across daemons where practical:

* Profile identity.
* Physical device identity.
* Device assignment.
* Device replacement.
* Measurement timestamps.
* Reception timestamps.
* Availability/status.
* Common API conventions.
* MQTT conventions.
* Basic measurement metadata.
* Unit representation.

---

# 47. What Should Not Be Normalized

Device-specific measurement functionality must remain device-specific.

Examples:

```text
O2Ring
├── Spot measurements
└── Continuous sessions

Blood pressure
├── Systolic
├── Diastolic
└── Pulse

Scale
├── Weight-only
└── Optional impedance/body composition

Glucose
└── Point-in-time glucose measurements
```

Normalization must not remove existing capabilities.

The Health Hub should adapt to what a daemon actually provides.

---

# 48. Design Decisions and Rationale

The final implementation documentation should preserve the reasoning behind significant architectural decisions.

This is important because some decisions intentionally introduce additional structure compared with the simplest possible implementation.

Examples include:

### Full O2Ring profiles

Profiles were added because the Health Hub must support multiple people and device replacement.

### Device identity separate from profile identity

A physical device can be replaced without changing the person.

### O2Ring spot versus session model

A point measurement and a continuous recording represent fundamentally different data.

### Weight-only scale operation

Weight-only operation is an existing supported mode and must not be removed or made dependent on impedance data.

### MQTT independent of Home Assistant

MQTT is intended to make the Hub useful to systems and people outside the Hub's own infrastructure.

### Home Assistant Discovery as an integration layer

Home Assistant should automatically discover Health Hub entities without making the Health Hub itself dependent on Home Assistant.

These rationales should remain with the requirements so future implementation work does not simplify away intentional design decisions.

---

# 49. Initial Release Scope

A reasonable first Health Hub release should concentrate on:

1. Unified current status.
2. Profile/device handling.
3. Multiple profiles.
4. Multiple physical devices over time.
5. Device replacement support.
6. Measurement timestamps.
7. Measurement freshness.
8. Device status.
9. Recent measurements.
10. O2Ring spot measurements.
11. O2Ring live status.
12. O2Ring session summaries.
13. Basic descriptive trends.
14. Unified REST API.
15. Normalized MQTT output.
16. Home Assistant MQTT Discovery.
17. Configurable 5-inch dashboard.
18. Display rotation.
19. Night mode.
20. Logging and error handling.

The existing device daemons and their detailed historical reporting remain outside the Health Hub's core responsibilities.

---

# 50. Overall Architecture

```text
                         PHYSICAL DEVICES
                                │
             ┌──────────────────┼──────────────────┐
             │                  │                  │
             ▼                  ▼                  ▼
        TrueMetrix           O2Ring           Etekcity
          daemon             daemon          Scale / BP
             │                  │                  │
             └──────────────────┼──────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   HEALTH HUB    │
                       │                 │
                       │ Profiles        │
                       │ Devices         │
                       │ Current data    │
                       │ Recent data     │
                       │ Trends          │
                       │ O2 sessions     │
                       │ API             │
                       │ MQTT            │
                       └───────┬─────────┘
                               │
              ┌────────────────┼─────────────────┐
              │                │                 │
              ▼                ▼                 ▼
         5" HDMI          REST API             MQTT
         Dashboard                              │
                                                │
                              ┌─────────────────┼──────────────┐
                              │                 │              │
                              ▼                 ▼              ▼
                         Home Assistant      Node-RED       Other
                         MQTT Discovery      openHAB        MQTT
```

## Core principle

> **The existing daemons remain the authoritative systems for their physical devices and detailed historical records. The Health Hub provides the unified current/recent view, aggregation, dashboard, API, and external MQTT integration.**

This architecture should allow the Hub to grow without sacrificing functionality that already exists in any of the four daemons.

