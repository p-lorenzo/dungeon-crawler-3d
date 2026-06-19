# Implementation Plan: Curved Dungeon Branches

**Branch**: `007-curved-dungeon-branches` | **Date**: 2026-06-18 | **Spec**: [specs/007-curved-dungeon-branches/spec.md](spec.md)

**Input**: Feature specification from `/specs/007-curved-dungeon-branches/spec.md`

## Summary

This feature adds support for winding and curved paths (both main path and secondary branches) in the procedural 3D dungeon generator. By default, paths are straight lines because room connectors have always been aligned on opposing sides. We will enable curved geometry by allowing the generator to place and align rooms with connectors oriented at non-opposing 90-degree angles (e.g. L-shaped corners, T-junctions). 

The spatial reasoning engine will:
1. Support generic transform alignments for 90-degree connector orientations.
2. Correctly compute the tight axis-aligned bounding box (AABB) of rotated rooms (by swapping local X and Z size coordinates for Y-rotations of 90/270 degrees).
3. Backtrack recursively to resolve collisions when curved paths wind back into existing layout structures.
4. Exclude verticality and loops/cycles (Y-height remains flat, layout remains a tree graph).

## Technical Context

**Language/Version**: GDScript (Godot 4.6)

**Primary Dependencies**: Godot Engine 4.6, Jolt Physics (project default)

**Storage**: Godot Resource serialization (`.tres`)

**Testing**: Headless integration tests run via Godot 4 (`Godot_v4.6.3-stable_linux.x86_64 --headless -s`)

**Target Platform**: Godot Editor (via `@tool`) and Runtime (Linux/Windows/macOS)

**Project Type**: Godot Editor Plugin

**Performance Goals**: Layout compile under 1.0 second

**Constraints**: Strict static typing mandatory, Core Logic Separation (memory-only spatial logic decoupled from SceneTree)

**Scale/Scope**: Flat layouts only (no vertical paths), Tree-graph layouts only (no loops/cycles), 90-degree increments only

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Constraint | Status | Verification / Action |
|------------------------|--------|-----------------------|
| I. GDScript & Static Typing & @tool | PASS | All files use strictly annotated GDScript; `DungeonGenerator3D` exposes in-editor preview buttons using `@tool`. |
| II. Core Logic Separation | PASS | All alignment and AABB overlap checks are performed in-memory inside `ConnectorMatcher`, `AABBManager`, and `DungeonBuilder` before SceneTree nodes are instantiated. |
| III. Signal-Driven Architecture | PASS | Uses `generation_completed`, `generation_failed`, and `generation_note` signals for status/logging propagation. |
| IV. Graph-Based Spatial Reasoning | PASS | Rooms are represented as a mathematical graph; spatial overlap tests (AABB) and path validation must pass. |
| V. Resource-Driven Configuration | PASS | Configuration parameters (pools, weights) stored in `DungeonConfig` and `RoomData`. |
| Technical Constraints | PASS | Strict static typing enforced, documentation in English, plugin code isolated under `plugins/dungeon_crawler_3d/`. |

## Project Structure

### Documentation (this feature)

```text
specs/007-curved-dungeon-branches/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── contracts/           # Phase 1 output
    ├── connector_matcher.md
    └── dungeon_builder.md
```

### Source Code (repository root)

```text
plugins/dungeon_crawler_3d/
├── core/
│   ├── aabb_collision.gd
│   ├── connector_matcher.gd
│   └── dungeon_builder.gd
├── nodes/
│   └── dungeon_generator_3d.gd
└── resources/
    ├── dungeon_config.gd
    └── room_data.gd

demo/
├── rooms/
│   ├── corner.tscn       # New 90-degree curve room
│   └── t_junction.tscn   # New 3-door junction room
└── test_curved_branches.gd # New curved branch integration test
```

**Structure Decision**: Fully unified project following the constitutional guidelines. Core algorithms live in `plugins/dungeon_crawler_3d/core/` and custom editor nodes live in `plugins/dungeon_crawler_3d/nodes/`. All test assets and test scripts live in `demo/`.

## Complexity Tracking

No violations of the constitution.
