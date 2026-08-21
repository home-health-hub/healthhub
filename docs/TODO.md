# TODO

Ideas not yet built, practical and speculative alike.

## Possible future devices

- **Beurer PO 60 fingertip pulse oximeter** — a spot-check device (clip on,
  read for a few seconds, done), not a continuous/overnight monitor like
  the O2Ring. Two reference implementations found, both MIT-licensed:
  - [Shreyan1/Beurer-PO60-PulseOximeter-Bluetooth-Integration](https://github.com/Shreyan1/Beurer-PO60-PulseOximeter-Bluetooth-Integration)
    — **preferred reference.** BLE via `bleak` (matches this project's usual
    stack, unlike the HID reference below) and targets the exact model
    (PO 60, not a sibling). Proprietary write/notify characteristics
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
    write-command bytes are unexplained ("magic" values, unverified), and
    the author's own note ("Pulse Rate will be added") suggests the PR
    parsing may not be fully verified despite being present in the code.
  - [stgloorious/hid-pulse-oximeter](https://github.com/stgloorious/hid-pulse-oximeter)
    — USB HID, written for the PO 80 specifically (VID `0x28e9`, PID
    `0x028a`), live BPM/SpO2 streaming only, no stored-session download,
    protocol only partially reverse-engineered. Kept as a fallback/
    cross-check, not the primary reference, now that a BLE PO 60-specific
    source exists — but still relevant if the PO 60 in hand turns out to
    only expose USB HID, or to sanity-check field meanings against a
    second independent implementation.

  Nothing here is confirmed against real hardware yet — needs
  hardware-in-the-loop verification once the PO 60 is on hand, same as
  every other device in this project. If it pans out, would follow the
  `<name>-ble` driver naming pattern (like `health-thermometer-ble`) and
  the reconnect/read-once-per-use daemon shape already used for the
  thermometer and BP daemons, not the O2Ring's session-history model.
