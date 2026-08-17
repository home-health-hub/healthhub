# Health Hub — Home Assistant MQTT Discovery Addendum

## 1. Purpose

The Health Hub will support **Home Assistant MQTT Discovery** as an optional integration feature.

This allows Home Assistant to automatically discover Health Hub measurements and device information without requiring the user to manually configure MQTT sensors.

Home Assistant integration must remain an **integration layer**, not a dependency of the Health Hub.

The Health Hub must remain useful with:

* Home Assistant
* Node-RED
* openHAB
* Other MQTT-aware systems
* Custom MQTT applications

---

## 2. MQTT Architecture

The Health Hub publishes two types of MQTT information:

1. **Normal Health Hub MQTT data**
2. **Home Assistant MQTT Discovery configuration**

The general architecture is:

```text
Device Daemons
      │
      ▼
 Health Hub
      │
      └── MQTT
           │
           ├── Health Hub data
           │
           └── Home Assistant Discovery
                    │
                    ▼
             Home Assistant
```

Home Assistant is therefore a consumer of the Health Hub's MQTT interface.

---

## 3. Health Hub MQTT Topics

The project's normal MQTT topics must **not** be Home Assistant-specific.

Health Hub data should use a project namespace such as:

```text
healthhub/...
```

For example:

```text
healthhub/william/o2/spo2
healthhub/william/o2/pulse
healthhub/william/bp/systolic
healthhub/william/bp/diastolic
healthhub/william/glucose
healthhub/william/weight
```

These topics must remain useful to any MQTT consumer.

The Health Hub must not require Home Assistant to consume its data.

---

## 4. Home Assistant Discovery

Home Assistant Discovery messages will use the MQTT Discovery mechanism required by Home Assistant.

Discovery messages describe:

* Entity name
* Entity type
* State topic
* Units
* Device class
* State class where appropriate
* Availability
* Device information
* Unique entity identifier
* Associated profile/device

After receiving the discovery configuration, Home Assistant creates the appropriate entities automatically.

---

## 5. Home Assistant Device Organization

The Health Hub should use Home Assistant's device/entity model to keep related measurements together.

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

The exact Home Assistant device hierarchy may be refined during implementation.

---

## 6. Profile Identity

Profiles must be represented independently of physical device identity.

For example:

```text
William
└── O2Ring
    └── Physical device
```

The Bluetooth MAC address or other hardware identifier identifies the physical device.

It must not become the permanent identity of the person.

This allows a physical device to be replaced without unnecessarily creating a new logical user identity.

---

## 7. Device Replacement

When a physical device is replaced, the Health Hub should retain the logical profile identity.

For example:

```text
William
├── O2Ring A
│   └── Historical data
│
└── O2Ring B
    └── Current device
```

Home Assistant entities should preferably remain associated with the logical Health Hub/profile identity rather than changing simply because the physical device was replaced.

---

## 8. O2Ring

The O2Ring supports both point-in-time measurements and continuous sessions.

These must be represented differently.

### Current O2Ring entities

Potential Home Assistant entities include:

```text
William O2 SpO2
William O2 Pulse
```

### Session information

Useful session-summary entities may include:

```text
William O2 Last Session Average SpO2
William O2 Last Session Minimum SpO2
William O2 Last Session Duration
```

The Health Hub should **not** create an MQTT entity for every raw O2Ring session sample.

Detailed session data remains the responsibility of the O2Ring daemon.

---

## 9. Blood Pressure

A blood-pressure measurement consists of related values.

Potential Home Assistant entities include:

```text
William Blood Pressure Systolic
William Blood Pressure Diastolic
William Blood Pressure Pulse
```

The underlying Health Hub data model must retain the fact that these values originated from the same measurement event.

MQTT representation should not destroy that relationship.

---

## 10. Scale

The Health Hub must support all operating modes provided by the scale daemon.

In particular:

**Weight-only operation must remain fully supported.**

The Health Hub must not require impedance or body-composition measurements.

If the scale provides only weight:

```text
William Weight
```

is sufficient.

If additional measurements are available, the Health Hub may expose corresponding additional Home Assistant entities.

Examples may include:

```text
William Weight
William Body Fat
William Muscle Mass
William Body Water
```

The existence of these entities must depend on the capabilities/data actually provided by the scale daemon.

Existing scale functionality must not be removed or restricted for the sake of normalization or Home Assistant integration.

---

## 11. Glucose

The glucose daemon can expose a Home Assistant glucose entity through MQTT Discovery.

Conceptually:

```text
William Glucose
```

The Health Hub must retain the actual measurement timestamp.

A glucose value must not be presented as current merely because it is the most recently received value.

---

## 12. Measurement Timestamps

MQTT entities should preserve measurement timing.

The underlying data should distinguish:

```text
measured_at
received_at
```

`measured_at` represents when the measurement actually occurred.

`received_at` represents when the daemon or Health Hub received the measurement.

This distinction is particularly important for glucose and O2Ring data.

---

## 13. Stale Data

The Health Hub must distinguish:

```text
Device unavailable
```

from:

```text
Device available but measurement is old
```

For example:

```text
Health Hub: Available
Glucose: 95 mg/dL
Measured: Yesterday 10:18 PM
```

The MQTT integration should provide enough availability/status information for Home Assistant to represent this appropriately.

---

## 14. Availability

MQTT availability should be used where appropriate.

At minimum, the Health Hub itself should provide an availability mechanism.

Device-level availability may also be exposed.

The system should distinguish between:

* Health Hub unavailable
* Device unavailable
* Device available with no recent measurement
* Current measurement available

---

## 15. Retained State

Current Health Hub state should use retained MQTT messages where appropriate.

This allows Home Assistant to recover the latest known state after restarting without waiting for another physical measurement.

Discovery configuration should also be retained as appropriate for MQTT Discovery.

---

## 16. Discovery Generation

Discovery information should be generated from the Health Hub's **actual profile, device, and measurement capabilities**.

The Health Hub must not assume that every device supports every measurement.

For example:

```text
Scale
└── Weight only
```

should produce only the appropriate weight entity.

A scale providing additional body-composition measurements may produce additional entities.

Likewise, O2Ring session entities should only be created for capabilities actually provided by the O2Ring daemon.

---

## 17. Configuration Changes

The Health Hub should republish appropriate discovery information when configuration changes affect the Home Assistant entity structure.

Examples include:

* Profile changes
* Device assignments
* Device replacement
* Newly available measurement capabilities
* Removed measurement capabilities

Unique entity identifiers should remain stable wherever the logical entity remains the same.

---

## 18. Home Assistant Independence

Home Assistant-specific functionality must remain isolated from the core Health Hub.

The core architecture should be:

```text
Health Hub
    │
    └── MQTT integration
         │
         ├── Generic MQTT data
         │
         └── Home Assistant Discovery
```

The Health Hub must not contain business logic that assumes Home Assistant is installed.

---

## 19. Design Principle

The key principle for Home Assistant integration is:

> **The Health Hub publishes a clean, normalized MQTT interface. Home Assistant MQTT Discovery maps that interface into Home Assistant entities.**

Home Assistant should be treated as **one consumer of the Health Hub**, not as the definition of the Health Hub's MQTT architecture.

---

## 20. Implementation Constraint

Home Assistant MQTT Discovery must not cause existing device-daemon functionality to be removed, simplified, or restricted.

The Health Hub must consume the capabilities provided by the device daemons rather than imposing a common set of measurements.

Existing functionality—including scale weight-only operation, device replacement, profiles, historical data, and O2Ring spot/session operation—must remain supported.

