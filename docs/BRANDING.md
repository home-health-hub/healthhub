# Home Health Hub branding

This guide keeps artwork across Home Health Hub repositories recognizable as one family while leaving room for each device to show its purpose.

## Core visual language

- Use rounded, approachable forms with gentle depth rather than hard-edged technical diagrams.
- Keep the background light: white fading into pale aqua.
- Use teal and aqua for devices, home-computing elements, storage, and connectivity.
- Reserve complementary colors for the measurement or function being highlighted.
- Show data staying in the home. Do not use cloud imagery.
- Prefer one clear left-to-right flow: device, connection, home computer, local storage.
- Avoid manufacturer logos, mascots, people, medical claims, arbitrary readings, and decorative interface text.

The hub logo in [`images/home-health-hub.png`](images/home-health-hub.png) is the primary visual reference.

## Palette

The artwork uses gradients, so these values are anchors rather than strict single-color fills.

| Role | Color | Hex |
|---|---|---|
| Deep teal | Titles, outlines, device shadows | `#00616E` |
| Hub teal | Devices and structural elements | `#168E98` |
| Aqua | Bluetooth icon and connectivity | `#31BEC1` |
| Pale aqua | Background fields and secondary shapes | `#C9F0EF` |
| Coral | Heart, pulse, and selected measurement accents | `#FF7A61` |
| Warm gold | Glucose transport accent | `#F5A623` |
| Oxygen blue | SpO2-specific live-data accent | `#28B9E8` |

The Bluetooth icon uses the same teal-to-turquoise treatment in every repository. Device-specific colors belong on the measurement path or related detail, not on the Bluetooth mark.

## README banners

README banners use a 3:1 landscape canvas. Keep the repository name exact, prominent, and limited to one appearance. At normal GitHub README width, the device and connection method should remain identifiable without relying on small labels.

Current daemon banners:

| Repository | Functional focus | Complementary accent | Image path |
|---|---|---|---|
| `etekcity-scale-daemon` | BLE scale measurements | Coral-orange | `docs/images/etekcity-scale-daemon-banner.png` |
| `etekcity-bp-daemon` | BLE blood-pressure measurements | Coral | `docs/images/etekcity-bp-daemon-banner.png` |
| `trividia-truemetrix-daemon` | Bluetooth and USB glucose import | Warm gold | `docs/images/trividia-truemetrix-daemon-banner.png` |
| `viatom-o2ring-daemon` | BLE live readings and overnight sessions | Oxygen blue with a small coral pulse accent | `docs/images/viatom-o2ring-daemon-banner.png` |

Place a banner directly below the README's level-one project title:

```markdown
# repository-name

![Concise description of the device-to-local-storage flow](docs/images/repository-name-banner.png)
```

Use meaningful alt text that states the device, connection method, and local destination. Do not repeat text that is already visible in the banner.

## Adding another device

Start from the same background, teal device family, Bluetooth treatment, typography, spacing, and local-storage motif. Choose one complementary accent based on the new measurement type. Keep that accent subordinate to the shared teal palette so the full set still reads as one system.
