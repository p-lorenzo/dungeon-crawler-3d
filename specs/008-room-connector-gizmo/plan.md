# Implementation Plan: Room Connector Editor Gizmos

**Branch**: `008-room-connector-gizmo` | **Date**: 2026-06-23 | **Spec**: [specs/008-room-connector-gizmo/spec.md](spec.md)

**Input**: Feature specification from `/specs/008-room-connector-gizmo/spec.md`

## Summary

This feature adds editor-time visual aids for `RoomConnector3D` nodes in the Godot 3D editor viewport. Designers need a quick way to align connectors facing the right direction (+Z pointing out of the room) and to verify that the connector width and height match the room's doorways.

To achieve this, we will:
1. Export `aperture_width` and `aperture_height` on `RoomConnector3D` nodes.
2. Implement a custom `EditorNode3DGizmoPlugin` called `RoomConnectorGizmoPlugin` to draw:
   - A wireframe rectangle representing the door opening size.
   - A directional arrow indicating the connector exit direction (+Z axis).
3. Connect the properties setter of `RoomConnector3D` to call `update_gizmos()`, forcing real-time redraws.
4. Register and unregister `RoomConnectorGizmoPlugin` in the main `EditorPlugin` lifecycle.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)

**Primary Dependencies**: Godot Engine 4.6

**Storage**: None (editor-only runtime parameters)

**Testing**: Visual verification in Godot Editor via demo scenes; script verification via headless plugin check.

**Target Platform**: Godot Editor (via `@tool` and `EditorPlugin`)

**Project Type**: Godot Editor Plugin

**Performance Goals**: Instant redraw on property changes (under 10ms), zero viewport lag.

**Constraints**: Strict static typing mandatory, plugin isolation under `plugins/dungeon_crawler_3d/`.

**Scale/Scope**: Editor-only helper gizmo; does not impact runtime game performance or procedural generation logic.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Constraint | Status | Verification / Action |
|------------------------|--------|-----------------------|
| I. GDScript & Static Typing & @tool | PASS | All script files use strictly annotated GDScript; `RoomConnector3D` and the new `RoomConnectorGizmoPlugin` use `@tool` and strict static typing. |
| II. Core Logic Separation | PASS | Editor visualization is isolated to the gizmo plugin and custom node; core procedural generator and spatial matching logic remain decoupled and memory-only. |
| III. Signal-Driven Architecture | PASS | Relies on property setters to trigger `update_gizmos()` dynamically rather than polling or frame-bound updates. |
| IV. Graph-Based Spatial Reasoning | PASS | Not directly applicable to editor gizmo drawing, but visualization aids in verifying correct graph layout structures. |
| V. Resource-Driven Configuration | PASS | Connectors are parameterized in the Inspector (`aperture_width`, `aperture_height`), allowing designers to configure individual doorway dimensions. |
| Technical Constraints | PASS | Strict static typing enforced, documentation in English, plugin code isolated under `plugins/dungeon_crawler_3d/`. |

## Project Structure

### Documentation (this feature)

```text
specs/008-room-connector-gizmo/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── contracts/           # Phase 1 output
    └── room_connector_gizmo_plugin.md
```

### Source Code (repository root)

```text
plugins/dungeon_crawler_3d/
├── nodes/
│   ├── room_connector_3d.gd           # Modified to export width/height and clamp values
│   └── room_connector_gizmo_plugin.gd  # New: EditorNode3DGizmoPlugin implementation
└── dungeon_crawler_3d.gd              # Modified to register/unregister the gizmo plugin
```

**Structure Decision**: Fully integrated with the existing plugin hierarchy. The new gizmo plugin script resides under `plugins/dungeon_crawler_3d/nodes/` alongside the nodes it visualizes.

## Complexity Tracking

No violations of the constitution.
