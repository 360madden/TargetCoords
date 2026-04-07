# Usage

## What you should expect in game

When the addon is loaded:

- a dark rectangular frame appears near the center of the screen
- the title reads `TargetCoords`
- three lines below it show `X`, `Y`, and `Z`

If no target is selected, the display should show:

```text
X: --
Y: --
Z: --
```

If a valid target is selected and coordinates are available, the display should update to live values.

---

## Basic Test Checklist

### 1. Addon loads

Confirm that RIFT shows the addon and that the frame appears.

### 2. No target state works

With no target selected, confirm the frame shows placeholder values.

### 3. Target selection updates

Select a nearby target and confirm the displayed coordinates populate.

### 4. Coordinate changes update

Move relative to the target, or observe target movement, and confirm the numbers update.

### 5. Target clearing works

Clear target and confirm the display returns to placeholder values.

### 6. Dragging works

Click and drag the frame. Confirm it follows the cursor without the text detaching.

---

## Common Failure Modes

### Frame appears but text is misplaced

Cause:
- bad frame dimensions
- unsafe text anchor choices
- dynamic layout math not matching actual text width

Current fix in this repo:
- larger fixed frame
- explicit text anchors
- no runtime relayout

### Target values never populate

Possible causes:
- target not actually inspectable yet
- no valid current target
- coordinate event did not include the selected target yet
- target details unavailable during zone/login transition

What this addon does:
- it refreshes on target changes
- it refreshes when the target becomes fully available
- it updates coordinates from coordinate events when possible

### Dragging snaps or behaves strangely

Possible cause:
- mixed anchor modes

What this addon does:
- it converts the frame to `TOPLEFT` anchoring before dragging begins

---

## Development Guidance

When extending this addon, keep these rules:

1. do not make visible labels the authoritative data source
2. do not reintroduce expensive layout churn on normal coordinate updates
3. keep target synchronization simple and explicit
4. add new telemetry fields into raw state first, then decide how to display or export them

---

## Good Next Steps

Reasonable next additions would be:

- optional saved frame position
- optional formatting controls
- additional target metadata
- structured export path for bridge/HUD use

Bad next steps would be:

- rebuilding the UI every time coordinates change
- coupling future telemetry transport to display labels
- adding abstraction layers before they are needed
