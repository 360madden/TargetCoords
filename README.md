# TargetCoords

`TargetCoords` is a small RIFT addon that displays the current target's world coordinates in a movable in-game frame.

This version is intentionally simple:

- fixed-size UI
- no dynamic relayout on coordinate churn
- raw data separated from formatted display text
- lightweight target sync
- documentation included

The immediate goal is a clean, stable addon-side base that can later feed a telemetry bridge or external HUD workflow.

---

## What It Does

`TargetCoords` shows the current target's:

- **X** coordinate
- **Y** coordinate
- **Z** coordinate

When there is no valid target or the target coordinates are not currently available, the addon shows:

- `X: --`
- `Y: --`
- `Z: --`

---

## Design Priorities

This addon was structured around a few practical rules:

1. **Responsiveness without UI waste**  
   The addon keeps target selection and coordinate updates responsive, but it does not keep recalculating frame layout when normal coordinate values change.

2. **Simple methods first**  
   The UI uses a fixed frame size and fixed text anchors. That avoids unnecessary text measurement, resizing, and repositioning.

3. **Separation of concerns**  
   Raw target state is stored separately from the visible text strings shown on screen.

4. **Safe base for future telemetry work**  
   The addon can later be expanded into a broader addon-side data source for an external reader or HUD.

---

## Repository Layout

```text
TargetCoords/
├── README.md
├── docs/
│   ├── ARCHITECTURE.md
│   └── USAGE.md
└── TargetCoords/
    ├── RiftAddon.toc
    └── TargetCoords.lua
```

---

## Installation

1. Close RIFT.
2. Copy the `TargetCoords` addon folder into your RIFT addons directory.
3. Typical Windows path:

```text
Documents\RIFT\Interface\AddOns\TargetCoords
```

4. Confirm these files exist after copying:

```text
Documents\RIFT\Interface\AddOns\TargetCoords\RiftAddon.toc
Documents\RIFT\Interface\AddOns\TargetCoords\TargetCoords.lua
```

5. Start RIFT and enable the addon.

---

## UI Behavior

- The frame starts centered on screen.
- The frame is draggable with the mouse.
- The frame uses a fixed layout.
- The visible text updates only when the displayed values actually change.

This keeps the UI path cheap and predictable.

---

## Data Behavior

The addon keeps separate internal state for:

- current target ID
- target coordinate availability
- raw X / Y / Z values
- visible display strings

That separation matters because future bridge or HUD work should consume **raw addon-side state**, not re-parse visible labels.

---

## Event Model

This version keeps the event model simple:

- `Event.Addon.Load.End` initializes the addon
- `Event.System.Update.End` watches for target selection changes
- `Event.Unit.Availability.Full` refreshes when the target becomes fully inspectable
- `Event.Unit.Detail.Coord` updates coordinate values for the current target

The older broad-refresh pattern was removed because it caused unnecessary work.

---

## Current Limits

This repo does **not** yet include:

- saved frame position
- bridge transport
- memory reader integration
- external HUD rendering
- broader target telemetry beyond coordinates

Those omissions are intentional for now.

---

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Usage](docs/USAGE.md)

---

## Development Notes

The current UI bug from the earlier fixed-layout pass was caused by a bad fixed-size/layout choice. The title and text placement were not sized safely. This version corrects that by using a larger fixed frame and explicit text anchors instead of relying on dynamic centering math.

---

## Status

This repository is now set up as a practical base for continued development.
