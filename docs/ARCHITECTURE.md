# Architecture

## Overview

`TargetCoords` is intentionally small. It is built around one core rule:

**keep the data path responsive and keep the UI path cheap.**

The addon tracks the current target, stores raw coordinate state, and updates a small fixed-position text display.

---

## High-Level Structure

The Lua file is organized into these sections:

1. configuration
2. runtime state
3. UI references
4. UI helpers
5. data helpers
6. drag handlers
7. startup
8. event registration

That keeps the file readable without introducing unnecessary abstraction.

---

## Data Path

The authoritative target data lives in `STATE.data`.

That state includes:

- `targetId`
- `hasTarget`
- `hasCoords`
- `coordX`
- `coordY`
- `coordZ`

This is the internal source of truth.

### Why this matters

If this addon is later used as part of a telemetry pipeline, other code should read structured state or structured output derived from that state. It should not treat the visible labels as the authoritative source.

---

## Display Path

The visible text lives in `STATE.display`.

That includes:

- `xText`
- `yText`
- `zText`

The display path is secondary.

### Display update rule

The labels are only updated when the displayed strings actually change.

That prevents unnecessary `SetText()` calls during normal operation.

---

## UI Layout Model

The UI is fixed-size.

### Why fixed-size was chosen

For this addon, dynamic frame resizing adds extra moving parts without enough benefit:

- text measurement work
- repeated label repositioning
- more failure cases
- more coupling between data updates and layout logic

A fixed frame avoids those problems.

### Layout approach

- the frame starts centered
- labels use explicit `TOPLEFT` anchors inside the frame
- the frame is moved by dragging, not by relayout

There is no coordinate-driven frame resizing.

---

## Target Sync Strategy

The addon uses a simple mixed strategy:

### 1. Snapshot refresh

`RefreshDataFromSnapshot()` performs a full target read:

- look up the current target ID
- fetch target details
- store raw coordinate values if available
- refresh visible text

This is the authoritative refresh path.

### 2. Lightweight target selection sync

`SyncTargetSelection()` checks whether the selected target changed.

If the current target ID differs from the stored target ID, the addon performs a snapshot refresh.

This keeps target switching responsive without relying on broad event spam.

### 3. Coordinate event refresh

`RefreshCoordsFromEvent()` updates only the raw coordinate values for the current target when coordinate event tables include that target.

This is cheaper than a full snapshot when the event already provides the updated values.

---

## Event Model

The addon uses four event paths:

### `Event.Addon.Load.End`
Initializes the addon for its own addon ID and runs the first snapshot refresh.

### `Event.System.Update.End`
Checks whether the selected target changed.

This does **not** perform layout work. It only compares the current target ID with the stored one and refreshes if needed.

### `Event.Unit.Availability.Full`
Refreshes when the current target becomes fully inspectable.

### `Event.Unit.Detail.Coord`
Updates raw coordinates when the current target appears in the coordinate event payload.

---

## Drag Model

The drag model is intentionally basic.

- on mouse down, the frame ensures it is anchored by `TOPLEFT`
- mouse offsets are captured
- on mouse move, the frame follows the cursor using the saved offset
- on mouse up, dragging stops

No persistence is included yet.

---

## Deliberate Omissions

These were intentionally left out to avoid overengineering:

- saved position
- screen clamping
- dynamic relayout
- generalized UI framework
- bridge transport layer
- external HUD integration

Those can be added later if they become necessary.

---

## Practical Direction for Future Work

If this addon evolves into a bridge source, the next steps should still respect the current design:

- keep raw state authoritative
- keep UI lightweight
- add structured export paths carefully
- avoid tying transport logic to visual labels

That is the correct long-term direction.
