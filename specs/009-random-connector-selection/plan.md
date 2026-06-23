# Implementation Plan: Random Connector Selection

**Branch**: `009-random-connector-selection` | **Date**: 2026-06-23 | **Spec**: [specs/009-random-connector-selection/spec.md](spec.md)

**Input**: Feature specification from `/specs/009-random-connector-selection/spec.md`

## Summary

Currently, `DungeonBuilder` picks the first available unused connector on a room sequentially. Because of this, dungeons always generate straight paths (front exit doors are always chosen first), resulting in straight corridors and rectilinear paths.

To create labyrinth-like dungeons with winding branches and organic turns, we will:
1. Modify `DungeonBuilder._find_unused_connector()` to collect all unused valid connectors.
2. Select one connector index at random from the collected set using `_rng.randi()`.
3. Retain complete seed reproducibility by ensuring this choice runs inside the seeded generator execution.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)

**Primary Dependencies**: Godot Engine 4.6

**Storage**: None (in-memory procedural algorithm)

**Testing**: Headless integration tests using `demo/test_random_connector_selection.gd`.

**Target Platform**: Godot Editor and Runtime

**Project Type**: Godot Editor Plugin

**Performance Goals**: Layout compile under 1.0 second, negligible impact of random index calculation.

**Constraints**: Strict seed reproducibility, Core Logic Separation.

**Scale/Scope**: Procedural generator layout algorithm only.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Constraint | Status | Verification / Action |
|------------------------|--------|-----------------------|
| I. GDScript & Static Typing & @tool | PASS | All files use strictly annotated GDScript; `DungeonBuilder` is pure GDScript with static typing. |
| II. Core Logic Separation | PASS | All path traversal, room matching, and randomization operate entirely in memory before instantiation. |
| III. Signal-Driven Architecture | PASS | Generates signals upon completion/failure. |
| IV. Graph-Based Spatial Reasoning | PASS | Preserves the mathematical AABB checks and path validations. |
| V. Resource-Driven Configuration | PASS | Configuration parameters and seeds are stored in `DungeonConfig` resources. |
| Technical Constraints | PASS | Strict static typing enforced, documentation in English, plugin code isolated under `plugins/dungeon_crawler_3d/`. |

## Project Structure

### Documentation (this feature)

```text
specs/009-random-connector-selection/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── quickstart.md        # Phase 1 output
```

### Source Code (repository root)

```text
plugins/dungeon_crawler_3d/
└── core/
    └── dungeon_builder.gd    # Modified: Randomize connector selection inside _find_unused_connector()
```

**Structure Decision**: Modified algorithm inside `plugins/dungeon_crawler_3d/core/dungeon_builder.gd`. Test script in `demo/test_random_connector_selection.gd`.

## Complexity Tracking

No violations of the constitution.
