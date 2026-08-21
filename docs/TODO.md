# TODO

Ideas not yet built, practical and speculative alike.

## Possible future devices

- **Beurer PO 60 / PO 80 fingertip pulse oximeter** — both are spot-check
  devices (clip on, read for a few seconds, done), not continuous/overnight
  monitors like the O2Ring. Worth supporting both as separate targets, not
  just using one as a fallback reference for the other — they're different
  transports with two independently-found, MIT-licensed references:

  - **PO 60 (BLE)** — [Shreyan1/Beurer-PO60-PulseOximeter-Bluetooth-Integration](https://github.com/Shreyan1/Beurer-PO60-PulseOximeter-Bluetooth-Integration).
    BLE via `bleak` (matches this project's usual stack) and targets the
    exact model. Proprietary write/notify characteristics
    (`...FF01`/`...FF02`), a two-command write sequence to trigger a
    reading, and a real packet format: `0xE9`-prefixed measurement packets
    carrying a packet number, an end-time (year/month/day/hour/minute/second,
    each byte-masked), and SpO2 max/min/avg — with pulse-rate max/min/avg
    arriving in a *separate* follow-up notification, not the same packet.
    One packet already looks like one complete reading session with its
    own summary stats and timestamp, which would map cleanly onto this
    project's one-row-per-use daemon shape without needing to average a
    live stream ourselves. Caveats: a bare single-file demo script (no
    device discovery, hardcoded MAC address, minimal error handling), the
    write-command bytes are unexplained ("magic" values), and the author's
    own note ("Pulse Rate will be added") suggests the PR parsing may not
    be fully verified despite being present in the code — this reference
    reads as less battle-tested than the PO 80 one below.
  - **PO 80 (USB HID)** — [stgloorious/hid-pulse-oximeter](https://github.com/stgloorious/hid-pulse-oximeter).
    VID `0x28e9`, PID `0x028a`, live BPM/SpO2 streaming only, no
    stored-session download, protocol only partially reverse-engineered
    (the init/configure packets have some unknown fields, `set_time()` is
    noted as not working). Worth treating as a real second target rather
    than just a cross-check: its README includes actual example output
    from a live run against real hardware, which the PO 60 reference above
    doesn't show — more likely to have actually been exercised against a
    physical device than just written and never run.

  Nothing here is confirmed against our own hardware yet — needs
  hardware-in-the-loop verification once a device is on hand, same as
  every other device in this project (a PO 60 is already on order; a
  PO 80 is not, so that path would need either borrowed/purchased hardware
  or would stay reference-only until one is available). If either pans
  out, would follow this project's usual naming (`<name>-ble` or
  `<name>-hid`, e.g. `health-thermometer-ble` / `trividia-truemetrix-hid`)
  and the reconnect/read-once-per-use daemon shape already used for the
  thermometer and BP daemons, not the O2Ring's session-history model.
