# Implementation Plan: First-Person Controller for Demo

**Branch**: `011-first-person-controller` | **Date**: 2026-06-23 | **Spec**: [specs/011-first-person-controller/spec.md](spec.md)

**Input**: Feature specification from `/specs/011-first-person-controller/spec.md`

## Summary

This feature adds a First-Person Controller (FPC) character to the demo so that users can walk through and test the procedurally generated dungeons from a player's perspective. 

We will:
1. Create a `FirstPersonController` scene and script under `demo/player/` containing `CharacterBody3D`, `CollisionShape3D`, and a `Camera3D` with mouse capture.
2. Build a new main demo scene `demo/demo_main.tscn` containing the generator.
3. Automatically spawn the player at the generated Entrance room's position on successful generation.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)

**Primary Dependencies**: Godot Engine 4.6, Jolt Physics

**Storage**: N/A

**Testing**: Headless structure validation check via `demo/test_player_controller_structure.gd` and manual playtesting.

**Target Platform**: Desktop (Windows/Linux/macOS)

**Project Type**: Godot Editor Demo

**Performance Goals**: Running at full framerate (60+ FPS), physics processing under 1ms per frame.

**Constraints**: All demo assets must reside under `demo/` and not leak into the published `plugins/dungeon_crawler_3d/` directory. Strict static typing in GDScript.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Constraint | Status | Verification / Action |
|------------------------|--------|-----------------------|
| I. GDScript & Static Typing & @tool | PASS | All files use strictly annotated GDScript; FPC scripts are statically typed. |
| II. Core Logic Separation | PASS | The controller is a demo gameplay asset and does not affect the core algorithm logic. |
| III. Signal-Driven Architecture | PASS | The orchestrator spawns the player in response to the generator's `generation_completed` signal. |
| IV. Graph-Based Spatial Reasoning | PASS | Spawning is parameterized by coordinates retrieved from the `DungeonGraph` structure. |
| V. Resource-Driven Configuration | PASS | Tunable parameters are exposed as standard Inspector fields on the nodes. |
| Technical Constraints | PASS | Strict static typing enforced, all files in English, isolation of code in `demo/`. |

## Project Structure

### Documentation (this feature)

```text
specs/011-first-person-controller/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
└── quickstart.md        # Phase 1 output
```

### Source Code (repository root)

```text
demo/
├── player/
│   ├── player.tscn       # First-Person player node
│   └── player.gd         # Movement, look, and input logic script
├── demo_main.tscn        # Playable orchestrator scene
├── demo_main.gd          # Orchestration script (generate & spawn)
└── test_player_controller_structure.gd # Structure validation script
```

**Structure Decision**: A new subfolder `demo/player/` is created to contain the player assets. The main playtest orchestrator scene lives as `demo/demo_main.tscn`.

## Complexity Tracking

No violations of the constitution.
