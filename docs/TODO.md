# TODO

Ideas not yet built, practical and speculative alike.

## Possible future devices

- **Beurer PO 60 / PO 80 fingertip pulse oximeter** — a spot-check device
  (clip on, read for a few seconds, done), not a continuous/overnight
  monitor like the O2Ring. [stgloorious/hid-pulse-oximeter](https://github.com/stgloorious/hid-pulse-oximeter)
  is a USB HID (not BLE) reference implementation for the PO 80 (MIT
  licensed): VID `0x28e9`, PID `0x028a`, live BPM/SpO2 streaming only, no
  stored-session download. Protocol is only partially reverse-engineered
  (the init/configure packets have unknown fields, `set_time()` is noted
  as not working). Not yet confirmed the cheaper PO 60 speaks the same
  protocol — needs hardware-in-the-loop verification once one is on hand,
  same as every other device in this project. If it pans out, would follow
  the `<name>-hid` driver naming pattern (like `trividia-truemetrix-hid`)
  and the reconnect/read-once-per-use daemon shape already used for the
  thermometer and BP daemons, not the O2Ring's session-history model.
