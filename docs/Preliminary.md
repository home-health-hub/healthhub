# Health Hub — Preliminary Architecture and Design Specification

> **Status:** Preliminary  
> **Purpose:** Establish the architectural decisions and requirements agreed upon so far.  
> **Implementation note:** Device-daemon-specific behavior, APIs, database schemas, and report-generation details remain subject to direct code review of the individual daemon repositories.

## 1. Purpose and Scope

Health Hub is a personal/household health-data appliance designed for use by an individual or household.

It is **not** intended to model a hospital, clinic, enterprise health-information system, or multi-station clinical environment.

The appliance provides a unified interface around independently useful health-device daemons while preserving those daemons as independent services and authoritative owners of their device data.

The primary user interface is the Health Hub Web UI.

Optional displays provide convenient, scoped views of authorized information. They are not required for normal operation.

## 2. Core Architectural Principle

Health Hub does not replace the existing device daemons.

The architecture is:

```text
Physical Device
      |
      v
Device Driver
      |
      v
Device Daemon
      |
      +---- SQLite long-term storage
      |
      +---- Device-specific PDF reports
      |
      +---- Public daemon API
      |
      v
Health Hub
      |
      +---- Web UI
      +---- Hub API
      +---- User/account management
      +---- Permissions
      +---- Administration
      +---- Backup
      +---- Cross-device presentation
      |
      +---- Optional displays
```

The daemon remains the source of truth for data obtained from its device.

The Hub consumes daemon APIs rather than directly manipulating daemon databases.

## 3. Single-Appliance Model

All Health Hub components are installed on the same physical machine.

The appliance is intended for one person or household.

The architecture does not require:

- multiple Hub stations;
- remote daemon machines;
- distributed daemon discovery;
- multiple Hub appliances;
- hospital-style centralized station management.

Additional stations, if ever required, would be a future feature rather than a current architectural requirement.

The Hub is best understood as something closer to a personal NAS appliance than a hospital information system: a single device that quietly does several jobs (collection point, data store, user interface, administration) rather than a network of specialized stations coordinated by a central authority.

This differs from a hospital workflow, where staff carry a portable vitals machine to the patient and then sync it to a separate central medical-record system. In the Hub, the collection point and the "central computer" are the same device — there is no separate synchronization step between a station and a back-end system.

Because every component runs on the same machine, the architecture does not need remote daemon registration, distributed authentication, WAN-facing APIs, or multi-Hub discovery; the Hub already knows what daemons are installed locally. The Hub API remains the correct boundary between the Hub and its daemons even on a single machine — it keeps the Hub from depending on daemon internals — but its transport can be as simple as a local Unix socket or a localhost-only HTTP interface, since it never needs to be exposed over a network.

## 4. Device Daemons

Supported device daemons are independent system services.

Current integrations under consideration include:

- TrueMetrix daemon;
- Viatom O2Ring daemon;
- Etekcity scale daemon;
- Etekcity blood-pressure daemon.

The daemons are useful independently of Health Hub.

A person may install and use a daemon without installing the complete Health Hub ecosystem.

A standalone daemon provides, according to its actual implementation:

- device communication;
- device-specific processing;
- long-term SQLite storage;
- device-specific API access;
- device-specific PDF report generation where supported.

The exact behavior of each daemon must be established from its source code before implementation requirements are finalized.

Installing the Health Hub must not be a prerequisite for using any of the standalone daemons. Someone may have no need for the Health Hub at all — they might install, for example, only the O2Ring daemon because they want its device driver, automatic acquisition, long-term SQLite storage, its PDF reports, and API access for their own scripts or application. The Health Hub depends on supported daemon APIs, but supported daemons must not depend on the Health Hub.

## 5. Daemon Storage

Each daemon owns its long-term device data.

SQLite is used for persistent daemon data.

The Hub does not become the authoritative replacement for these databases.

The conceptual ownership model is:

```text
Device
  |
  v
Daemon
  |
  v
Daemon SQLite database
  |
  v
Daemon API
```

The Hub communicates with the daemon through its API.

The Hub should not directly access daemon SQLite databases as its normal data interface.

This prevents the Hub from becoming coupled to:

- daemon database schemas;
- SQLite implementation details;
- internal daemon objects;
- daemon storage migrations.

## 6. Device-Generated PDF Reports

Device-daemon PDF reports are intended for **patient/doctor consumption**.

They are not merely convenience exports.

The daemon that understands the device is responsible for generating its device-specific report.

The conceptual flow is:

```text
Device
  |
  v
Daemon
  |
  v
Device-specific measurements
  |
  v
Device-specific PDF report
```

The Health Hub provides access to those reports but does not replace the daemon's report-generation functionality.

Health Hub may additionally provide its own user-facing summaries, charts, and cross-device visualizations.

Those Hub-generated summaries are distinct from daemon-generated patient/doctor reports.

## 7. Health Documents

Health documents supported by the current scope include device-data PDF reports and related visual representations of device measurements.

The current scope does **not** include:

- medical laboratory reports;
- general clinical reports;
- arbitrary medical-document management;
- replacing a clinic's medical-record system.

Charts and graphs generated by Health Hub should be based on the supported device measurements available through the daemons.

The Hub should not offer medical interpretation or diagnosis. Hub-generated summaries should describe trends in the data ("your average systolic value increased compared with the previous period") rather than medical conclusions ("your blood pressure is dangerous"). Users may define personal, non-medical targets (for example a weight goal) and see their progress toward them; this is distinct from medical advice.

## 8. Daemon APIs

Daemon APIs are user-reachable APIs.

They are not merely internal machine-to-machine interfaces.

A daemon may be used by:

- Health Hub;
- `curl`;
- user scripts;
- automation;
- other applications.

The Health Hub is one consumer of the daemon API, not the reason the API exists.

Conceptually:

```text
                  Device Daemon
                       |
                Public/API interface
                       |
          +------------+------------+
          |            |            |
       Health Hub     curl       Scripts
```

The daemon API should therefore be treated as a supported public interface.

API versioning is required so that daemon updates do not silently break existing clients.

For example:

```text
/api/v1/...
```

A daemon's API should expose supported device concepts rather than implementation details.

The API should not require clients to understand:

- SQLite table names;
- internal Python objects;
- private functions;
- internal filesystem layout.

Exact endpoints and schemas must be based on direct review of the existing daemon implementations.

Different daemons should not be forced into one generic device API. An O2Ring daemon and a glucose-meter daemon do not naturally expose the same operations: O2Ring concepts include spot measurements, recorded sessions, time-series samples, and session reports, while a glucose meter's concepts are closer to individual readings, meter history, and measurement reports. Each daemon's API should reflect its own device's actual capabilities and behavior; the Hub is responsible for normalizing across daemons at its own layer when it needs a unified, cross-device view.

## 9. Health Hub API

Health Hub also provides an API.

Its purposes include:

- Web UI communication;
- user/script automation;
- `curl` access;
- integration with other applications.

The Hub API must use the same authorization model as the Web UI.

An API client must not be able to bypass permissions simply because it uses `curl` instead of the Web UI.

Scoped API credentials may be used for automation and optional displays.

For example, a user could issue a scoped credential for a personal export script:

```text
API credential

Name:
Weight Export Script

Owner:
William

Scope:
Read weight data

Expires:
Never
```

The credential can be revoked independently of the owner's normal login credentials. Security-sensitive API operations should appear in the same administrative audit log as equivalent Web UI actions, so that `curl`/script access does not become an unaudited side channel. The API does not create a second permission system — it exposes the same authorization model used by the Hub.

## 10. MQTT

**Revised decision:** MQTT is used for both the Hub's near-real-time push channel *and* external automation. This revises the original position (that MQTT was solely for external consumers) after code-level review of the four existing daemons showed each one already implements an off-by-default MQTT publish that fires on every new reading (`<topic_prefix>/<device_id>/state`), independent of whether anything is subscribed. That existing, already-working mechanism is a better fit for Hub-to-daemon push than adding a new bespoke webhook to every daemon.

The daemon REST API remains the mechanism for on-demand queries, configuration, reports, profile assignment, and capability discovery. MQTT is used specifically for near-real-time delivery of new readings, so the Hub does not need to poll four daemons on an interval.

MQTT continues to also serve:

- Home Assistant;
- Node-RED;
- other MQTT-based automation systems;
- other external automation consumers.

Conceptually:

```text
Device Daemon
     |
     +---- API ----> Health Hub / users / scripts (on-demand: query, config, reports, capabilities)
     |
     +---- MQTT ---> Health Hub (near-real-time push)
     |            \-> Home Assistant / other automation (external consumers)
```

A daemon publishes to MQTT without knowing or caring whether the Hub, Home Assistant, both, or neither is subscribed — enabling MQTT for Hub use does not create a dependency of the daemon on the Hub. MQTT does not replace the daemon API; it supplements it for the specific case of "notify me as new data arrives."

Each daemon now also exposes a `GET /api/v1/capabilities` endpoint (unauthenticated, like `/health`) describing its measurement types, measurement modes, profile model, timestamp semantics, and whether/where it publishes to MQTT — so the Hub can auto-configure its subscriptions per daemon instead of hardcoding topic assumptions. All daemon REST APIs are now versioned under `/api/v1/`.

### Raw Daemon Feed vs. Hub Normalized Feed

Both are legitimate, documented ways for a person to get Health Hub data over MQTT, and installation/administration documentation should explain both rather than only the Hub's own output:

- **Raw daemon feed** — enable `[mqtt]` on a specific daemon and subscribe to its topic directly. Fastest, works even without the Hub installed, but is scoped to one physical device rather than a person, and for daemons where profile tagging happens after the fact (the scale and blood-pressure daemons), a raw reading may arrive with no profile resolved yet.
- **Hub normalized feed** — subscribe to the Hub's own published topics, or use Home Assistant Discovery. Person-scoped, consistent shape across every device type, includes the Hub's freshness/availability handling, but requires the Hub to be installed and running.

The technical daemon-by-daemon detail and full comparison lives in the Health Hub Technical Design Specification (Section 26.1).

### Publish Rights Are Restricted to Daemons and the Hub

Only a device daemon (on its own topics) and Health Hub (on its own topics) may publish to MQTT. Every other client — Home Assistant, Node-RED, openHAB, custom scripts, dashboards — is subscribe-only, enforced by the broker's own access control rather than by convention. There is currently no supported case where an external consumer needs to write back into Health Hub's or a daemon's topics; a write ability would only invite spoofed readings or fabricated state. See the Technical Design Specification (Section 26.2) for the enforcement mechanism.

## 11. Systemd Services

Device daemons remain independent systemd services.

The Hub is also a system service.

Conceptually:

```text
systemd
  |
  +-- healthhub.service
  +-- trividia service
  +-- viatom-o2ring service
  +-- etekcity-scale service
  +-- etekcity-bp service
```

The Hub may provide administrative visibility into daemon status and may eventually provide controlled lifecycle management, but the daemons remain independent services.

A daemon failure should not inherently make the entire Hub unusable.

Existing daemon data should remain available even if another component is temporarily unavailable.

## 12. User Interaction

The Hub station does not detect the presence or identity of a person.

There are no assumptions of:

- cameras;
- biometric recognition;
- proximity sensors;
- automatic person detection.

A session is explicitly initiated by the user.

### Browser/Phone/Tablet Session

A user may:

1. Log into their Health Hub account using a phone, tablet, or browser.
2. Select that they want to interact with the Hub station.
3. Select the station.
4. The Hub station displays a confirmation code.
5. The user enters/confirms that code through their authenticated device.
6. The session becomes associated with that user.

After confirmation, the user can select which device they are interacting with.

For example:

```text
User
  |
  v
Authenticated Web UI
  |
  v
Select Hub station
  |
  v
Enter station confirmation code
  |
  v
Select device
  |
  v
Interact with scale/BP monitor/etc.
```

### USB Keys

USB keys are optional for normal users.

A user who has a USB key may use it as an alternative identification mechanism at the station.

USB keys are particularly relevant to administrator authentication but are not required for every user.

## 13. Main Hub Interface

The Web UI is the primary viewing and interaction interface.

The physical Hub screen is required because it provides:

- session confirmation codes;
- pairing information;
- device/session information;
- other information that needs to be displayed at the station.

The physical screen is not intended to be the primary general-purpose health-data interface.

## 14. Optional Convenience Displays

Additional displays are optional.

They are intended to provide quick access to information in places such as:

- a child's room;
- a bedroom;
- another household location.

For example, a parent may want a child's display to show authorized health information without requiring the parent to keep their phone/tablet beside them.

These displays are convenience interfaces, not required Hub stations.

Each display uses a scoped API key identifying what information that display is authorized to receive.

The display does not determine authorization.

The Hub determines what the display is permitted to access.

A display key does not grant user-account access. For example, a child's-room display's key might be scoped like this:

```text
Display: Child bedroom display

Allowed:
✓ Child's profile
✓ Weight trend
✓ Temperature

Denied:
✗ Parent data
✗ Other household members
✗ Full medical history
✗ User settings / administration
```

Displays are created from the Web UI: an owner picks the assigned person and the specific information the display may show, and the Hub generates the display's key at that point. If a display is lost, its key can be disabled without affecting the assigned user's account or any other display's key.

## 15. User and Administrator Model

### Super Hub Administrator (SHA)

Exactly **one SHA exists at any time**.

The SHA is the highest administrative authority for the Hub.

Only the SHA can create a Hub Administrator.

Actions requiring SHA authority include:

- creating a Hub Administrator;
- removing a Hub Administrator;
- changing encryption settings;
- initiating key changes/rotation;
- ownership-level administrative operations.

All key changes require the SHA to initiate the change.

There is no two-person approval system. A mandatory multi-administrator approval requirement was explicitly considered and rejected: it can turn a lost or unavailable administrator into a permanent lockout. Health Hub is a household appliance, not a corporate banking system, so the design favors clear, recoverable ownership over multi-party approval.

A key can be **disabled** (temporary) or **revoked** (permanent). Disabling stops a key from authenticating while preserving its permissions and audit history, and only the SHA can re-enable it; this is intended for situations such as a temporarily misplaced key. Revoking permanently invalidates a key and requires new SHA-controlled enrollment if access is needed again; key records are never actually deleted, only moved through this lifecycle, so audit and recovery history is preserved. Disabling or revoking an administrative key removes only the privileges tied to that key/role — it does not remove the person's ability to use the Hub as a normal health-system user, and does not delete their health history or user account. Fully removing a person is a distinct, separately confirmed operation because it affects historical health records, data ownership, and audit information.

### Hub Administrator (HA)

Hub Administrators can perform administrative tasks delegated to them by the system/SHA.

HA capabilities may include:

- Hub software administration;
- supported device integration administration;
- normal user administration;
- other operational administration permitted by the SHA.

HA access to user Samba shares and health documents is configurable by the SHA.

### System Recovery Administrator

The System Recovery Administrator is a separate, narrower authority focused on disaster recovery rather than day-to-day Hub administration. A System Recovery Administrator can restore the host OS, restore the Hub installation, and restore backups. They cannot add integrations, approve third-party software, read other administrators' secrets, or manage Hub configuration. This preserves a clear separation between recovery authority and administrative authority, so that a person trusted to recover the system in an emergency is not automatically trusted with day-to-day control of it. Recovery restores system state; it does not change any user's health-data access permissions, and a Recovery Administrator has no automatic access to health data.

### User Administrator

The User Administrator is a narrower role than a full Hub Administrator, scoped to normal-user account management: creating, disabling, and resetting access for normal users, and managing user profiles. A User Administrator cannot create Hub Administrators, modify encryption, or manage recovery administrators — this prevents a delegated user manager from accidentally becoming a system owner.

### Normal Users

Normal users can use the Health Hub for personal health-system functions and access information for which they have permission.

They do not need to understand:

- daemon APIs;
- SQLite;
- Apprise syntax;
- internal storage;
- systemd;
- Python virtual environments.

### Health Data Access

Technical/administrative authority and health-data access are two separate systems: holding a technical role (SHA, HA, System Recovery Administrator, User Administrator) does not by itself grant access to any user's personal health data. By default, every user owns and can view/enter only their own health data.

A user may delegate access to their own data to another person, at one of a few permission levels:

- **View only** — view history and charts, no changes.
- **Data entry assistance** — view history and add new readings, but not modify existing records.
- **Caregiver/full health management** — view, add, and correct/manage records.

Administrators cannot grant themselves access to another user's health data; access must come from that user's own delegation. Health-data permission changes (grants and revocations) should be recorded in the audit log, separately from system-administration audit events. There is no separate encryption layer specific to health data — access is controlled through authentication, roles, and permissions rather than a second encryption system, to avoid the added complexity, recovery risk, and migration burden of maintaining multiple encryption boundaries.

## 16. Samba Access

Samba provides a convenient way for authorized users and administrators to access files through normal network file browsing.

"Samba convenience" refers to making file access easier for the user; Samba is not merely an optional architectural component whose presence is undecided.

The Hub permission model remains authoritative.

Users should not need to know internal filesystem paths or daemon storage structures to access their authorized files.

The SHA has administrative access to user Samba shares.

HA access to user Samba shares may be restricted by the SHA.

## 17. Apprise Notifications

Administrators and users should not be required to understand Apprise syntax.

The Hub should present supported notification backends that are actually activated for the installation.

For each notification/alert type, the administrator is presented with the available configured backends and the fields required by that backend.

For example:

```text
Alert Type

Backend:
[ Select configured backend ]

Name:
[________________]

Mail:
[________________]

Password / Token:
[________________]

[ Save ]
```

The Hub handles the underlying Apprise configuration.

The administrator should not have to manually construct Apprise URLs.

Apprise is a delivery mechanism, not the whole notification system. The Hub owns a built-in alert engine that is responsible for alert creation, severity, deduplication, permissions (who is allowed to receive an alert about whom), acknowledgement, and history; Apprise-backed providers (and the Web UI and optional displays) only handle final delivery. Repeated readings of the same underlying condition (for example, several elevated-temperature samples in a row) should update one alert rather than generating a new notification each time.

Health alerts and system alerts should be kept conceptually separate, because their recipients are determined differently:

- **Health alerts** (e.g. a fever reading, an abnormal blood-pressure reading) are routed according to each user's health-data delegation — a caregiver only receives an alert about someone whose data they are authorized to see.
- **System alerts** (e.g. backup failed, disk full, update available, a key nearing expiration) are routed according to technical role — for example, only the SHA and Hub Administrators, not normal users.

## 18. Backup

The Hub provides local backup capability by default.

The system should use honest terminology.

A local copy should not be represented as complete protection against every form of loss.

The UI should communicate that additional independent copies provide better protection.

Example:

```text
Local backup:
Enabled

Additional copy:
Not configured
```

An installation with another backup destination can communicate the improved protection level.

Advanced backup destinations may include rclone-supported destinations.

Normal administrators should not need to understand rclone syntax.

The default local backup is honestly a **local recovery copy** rather than a full backup: it lives on the same Hub storage as the live data, so it protects against accidental deletion, bad configuration changes, failed updates, and software corruption, but it does **not** protect against disk failure, theft, fire, or other physical loss of the Hub device. Two further, advanced tiers improve on this: a **local external backup** (e.g. to a USB drive or NAS) additionally protects against disk failure and simplifies reinstall; an **off-site backup** (e.g. via rclone to a remote/cloud destination) additionally protects against physical loss of the home itself. The Web UI should present this honestly — for example, showing local recovery copies as enabled while flagging that no protection exists yet against storage failure until an external destination is configured — without resorting to alarming language.

## 19. Unrecoverable Data

"Unrecoverable" should be used when describing data that can no longer be restored.

The term makes clear that the issue is not simply temporary unavailability.

For example:

```text
Unavailable:
The Hub cannot currently access the data.

Unrecoverable:
No valid copy of the required data or encryption material exists
from which the data can be restored.
```

The system should explain that maintaining additional copies improves protection against unrecoverable loss without using unnecessarily alarming language.

## 20. Debian and Host Operating System

The SHA is considered the host operating-system administrator.

The Hub controls Hub software.

The SHA decides whether host operating-system applications should be installed automatically or manually.

The Hub should not assume control over unrelated host software.

The installation must support pinning the host Debian release to a specific version when required by other software installed on the same machine.

The administrator should still be able to obtain newer supported software when desired.

This is particularly relevant when the Hub appliance has other purposes or applications that require a specific Debian release.

## 21. Python Virtual Environments

Hub Python software uses controlled virtual environments so that host-installed Python modules cannot unexpectedly break Hub software.

The Hub installer and updater know which virtual environments are required.

Administrators do not need to manually manage those environments during normal operation.

The Hub virtual environment must not be writable by normal users.

The documentation should explicitly state:

> **The Hub virtual environment should not be modified by normal users. It should be treated as managed application infrastructure. Manually installing, removing, or replacing packages inside it can break the Hub system.**

The same principle applies to daemon-specific virtual environments where applicable.

For example, Hub software and its dependencies would live under a dedicated tree separate from the daemons and the host, along the lines of:

```text
/opt/healthhub/
├── app/       (Hub application code)
├── venv/      (Hub-managed Python virtual environment)
├── config/
├── data/
└── backups/
```

Because the Hub runs from its own virtual environment, the host may run a different Python version, or have other Python packages installed, without affecting the Hub.

## 22. Software Updates

The Hub Web UI informs the SHA/appropriate administrator when Hub software requires updating.

The actual update is performed through documented CLI commands.

The administrator should not have to guess the command order or recovery process.

Update documentation must provide:

1. The command to run.
2. The required command order.
3. What each step does.
4. Expected results.
5. Validation steps.
6. Recovery procedures if an update fails.

The Hub updater knows about its managed Python virtual environment and other Hub-specific requirements.

The Web UI should notify the SHA that an update is available; it should not itself offer an "Update Now" action. Performing updates through documented CLI commands rather than the Web UI is deliberate: it keeps updates workable even if the Web UI itself is broken, is easier to document and automate, and avoids a normal user accidentally triggering an update. While an update is being applied, the Hub may enter a maintenance mode in which normal read/write operations (such as recording a new measurement) are paused, so that an in-progress update cannot corrupt data.

## 23. Software Ownership Boundaries

The system maintains a clear distinction between:

```text
Host OS
    |
    +-- SHA responsibility

Health Hub
    |
    +-- Hub software administration

Device Daemons
    |
    +-- Independent system services
    +-- Device-specific administration
```

The Hub must not require the SHA to understand internal Python dependency management.

Likewise, administrators should not modify managed virtual environments as part of normal administration.

## 24. Logging and Auditing

The Hub should provide a human-readable system status view.

It should show:

- Hub status;
- daemon status;
- device status where available;
- recent errors;
- last successful communication;
- other useful operational information.

Daemon logs remain daemon logs.

The Hub should not replace the daemons' normal systemd/journald logging.

For example, the human-readable status view could look like:

```text
System Health

Hub
  Running

O2Ring daemon
  Running
  Last device contact: 10:42

Blood Pressure daemon
  Running
  Last measurement: 09:18

Scale daemon
  Running
  Last measurement: 08:03

TrueMetrix daemon
  Running
  Last device contact: 07:51
```

Device/daemon errors should remain associated with the daemon that produced them (for example, "O2Ring — last error: unable to connect to device — 10:43") rather than being hidden behind a generic "something went wrong" message, so an administrator has enough information to know what needs attention.

The Hub should maintain an administrative audit log for security-sensitive Hub operations.

Audit entries should identify at minimum:

- who performed the action;
- what action occurred;
- when it occurred;
- whether it succeeded or failed.

For example:

```text
2026-08-17 09:15

Administrator: SHA
Action: Changed encryption configuration
Result: Successful
```

Examples of actions requiring an audit entry include:

- administrator creation/removal;
- key changes;
- encryption configuration changes;
- permission changes;
- device integration changes;
- recovery operations.

Ordinary Hub Administrators should not be able to edit or delete audit history, including entries about their own actions.

## 25. Health Data Ownership

The daemon remains authoritative for measurements produced by its device.

The Hub does not replace daemon long-term storage.

The relationship is:

```text
Daemon SQLite
    |
    +-- authoritative device data

Health Hub
    |
    +-- authorized presentation
    +-- user/household organization
    +-- cross-device views
    +-- access control
```

The Hub may normalize information for presentation without taking ownership of the underlying device data.

## 26. Report Access

Daemon-generated PDFs are intended for patient/doctor consumption.

The Hub makes authorized reports accessible to the patient.

The Hub is not intended to become a medical-provider portal.

The patient can provide reports to healthcare providers using existing methods, including:

- printing the report;
- submitting it through the clinic's patient portal;
- using another method approved by the healthcare provider.

The system will not introduce a permanent doctor-account system for this purpose.

## 27. Architectural Constraints

The following decisions are considered settled unless explicitly revisited:

- Health Hub is a single household appliance.
- All components normally run on the same physical machine.
- Device daemons remain independent systemd services.
- Daemons remain independently usable without Health Hub.
- Daemons communicate with devices through their drivers.
- Daemons maintain long-term device data in SQLite.
- Daemons remain the source of truth for their device data.
- Daemons provide device-specific PDF reports.
- Daemon APIs are user-accessible APIs.
- Health Hub consumes daemon APIs.
- Health Hub also provides its own API for Web UI, `curl`, scripts, and applications.
- MQTT is used both for the Hub's near-real-time push channel (subscribing to each daemon's existing publish-on-reading feature) and for Home Assistant/other external automation; the daemon REST API remains the mechanism for on-demand queries, config, reports, and capability discovery.
- Daemon REST APIs are versioned under `/api/v1/`.
- Each daemon exposes a `GET /api/v1/capabilities` endpoint (unauthenticated, like `/health`) so the Hub can auto-discover measurement types, modes, profile model, timestamp semantics, and MQTT availability instead of hardcoding per-daemon assumptions.
- The Web UI is the primary user interface.
- The Hub station has a screen for codes and session information.
- The station does not detect the presence or identity of people.
- Users explicitly initiate sessions.
- Phone/tablet/browser confirmation is supported.
- USB keys are optional for normal users.
- Optional displays use scoped API keys.
- Only one SHA exists at any time.
- Only the SHA can create a Hub Administrator.
- Key changes require SHA initiation.
- Encryption-setting changes require SHA authority.
- There is no two-person approval system, because mandatory multi-administrator approval risks permanent lockout in a household appliance.
- Administrative keys can be disabled (temporary) or revoked (permanent); disabling/revoking an administrative role does not remove the person's normal-user access or delete their data.
- The System Recovery Administrator is a role separate from the Hub Administrator, scoped to disaster recovery only.
- The User Administrator is a role separate from the Hub Administrator, scoped to normal-user account management only.
- Health-data access is independent of technical/administrative role; every user owns their own data by default and must explicitly delegate access to anyone else, including administrators.
- HA access to user Samba shares can be restricted by the SHA.
- Samba provides convenient authorized file access.
- Administrators/users do not need to understand Apprise syntax.
- The Hub owns a built-in alert engine (severity, deduplication, permissions, history); Apprise-backed providers only handle delivery.
- Local backup is the default, and by itself is a local recovery copy, not protection against disk failure, theft, or fire.
- Additional backup copies improve protection.
- Remote/rclone backup is an advanced configuration.
- The Web UI reports available software updates; it does not perform updates itself.
- CLI procedures perform updates.
- Host OS decisions remain under SHA control.
- Hub Python environments are managed by the Hub installer/updater.
- Normal users must not modify Hub virtual environments.
- The Hub does not silently absorb unrelated host-OS responsibilities.
- Supported daemons must remain independently usable and must not depend on the Health Hub.

## 28. Pending Code-Level Investigation

A first pass of direct source-code review has been completed for the API/storage/config layer of all four daemons (below). Still outstanding, and requiring further review before implementation requirements are fully finalized:

- device communication mechanisms and underlying driver/BLE libraries;
- device discovery and pairing/connection behavior;
- measurement acquisition and processing internals;
- long-term retention/pruning behavior (each daemon has a `test_prune.py`, suggesting retention is implemented, but the policy itself hasn't been reviewed here);
- report generation internals and exact PDF contents/layout;
- detailed error handling behavior;
- systemd service behavior beyond the unit files already listed;
- dependencies;
- any externally useful functionality not covered below.

These remaining findings must still be incorporated into the final architecture rather than replaced with assumptions.

### Confirmed From Source Review (API / Storage / Config layer)

All four daemons (TrueMetrix, Viatom O2Ring, Etekcity scale, Etekcity blood-pressure) were reviewed directly. Findings:

- **REST API**: all four use `aiohttp.web`. All four now expose versioned routes under `/api/v1/` and a `GET /api/v1/capabilities` endpoint (unauthenticated, like `/health`) reporting measurement types, measurement modes, profile model, timestamp semantics, and MQTT availability. Auth is an optional shared bearer token per daemon (no per-caller scoping at the daemon level — scoped/revocable credentials, per Section 9, are a Hub-API concept, not a daemon-API one).
- **MQTT**: all four already implement an off-by-default publish-on-new-reading feature (`<topic_prefix>/<device>/state`), independent of any subscriber's existence. This is now the basis for the Hub's near-real-time push channel (see Section 10).
- **Alerting**: all four use Apprise for condition-triggered human notifications (staleness, out-of-range values) via an hourly/15-minute systemd timer — this is a notify-a-person mechanism only, not a data channel, and is unrelated to the MQTT/capabilities work above.
- **Profile model differs by daemon, and this is expected, not an inconsistency to fix**: TrueMetrix and the Etekcity daemons store measurements with a nullable profile, tagged after the fact via an `/assign-*` endpoint; the O2Ring daemon instead represents a single wearer per daemon instance via static config, since one daemon process talks to one ring. The Hub must consume whichever model each daemon actually implements (reported via `/api/v1/capabilities`) rather than assuming one uniform model.
- **Timestamp semantics differ by hardware, and some of this is a hardware limit, not a software gap**: TrueMetrix has `device_time` (meter clock) and `synced_at` (daemon ingestion); O2Ring cleanly separates live-reading `recorded_at` from session `start_time`/`downloaded_at`; the Etekcity scale and BP daemons only have a single `recorded_at` (arrival time) — the BP cuff's BLE protocol carries no device-side clock at all, so a true measured_at is not obtainable in software for that device.
- **O2Ring confirms the spot-vs-session split** anticipated in Section 14/28: `live_readings` and `sessions`/`session_records` are genuinely separate tables, not a single flat measurement table.
- **The Etekcity BP cuff's on-device "user" memory slot (0 or 1) is confirmed to be internal device memory, not a Health Hub profile** — the daemon stores it separately from the nullable `profile` column, consistent with the Hub (not the device) assigning a measurement's owner.
- **The scale and BP daemons confirmed to report a bare device reading with no Hub user attached** until explicitly assigned — matching the household-scale scenario in Section 12.

## 29. Status of This Document

This document captures the current architectural direction and confirmed decisions.

It is **not yet an implementation specification**.

The next stage is to perform the source-code review of the individual daemons and use those findings to define:

- precise daemon/API contracts;
- data models;
- Hub integration requirements;
- report handling;
- device workflows;
- authentication;
- filesystem layout;
- installation procedures;
- update procedures;
- backup/restore procedures;
- concrete implementation requirements.
