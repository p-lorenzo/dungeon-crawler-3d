# Implementation Plan: Procedural Dungeon Generator

**Branch**: `001-procedural-dungeon-generator` | **Date**: 2026-06-18 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-procedural-dungeon-generator/spec.md`

## Summary

Build a Godot 4.6 editor plugin for procedural 3D dungeon generation. Level designers configure topology parameters (main path length, branch count, branch depth range) and assign prefab rooms to per-category pools. The generator constructs a dungeon graph in memory — matching connectors, avoiding AABB overlaps, validating path connectivity — then instantiates the result in the SceneTree. All generation runs via `@tool` scripts directly in the editor. The system focuses on exact connector matching, no tile-based approach, and full in-editor iteration.

## Technical Context

**Language/Version**: GDScript (Godot 4.6, static typing mandatory)

**Primary Dependencies**: Godot Engine 4.6 (no external libraries), Jolt Physics (project default)

**Storage**: `.tres` / `.res` files (Godot Resource serialization) for DungeonConfig and RoomData

**Testing**: Manual testing via `demo/` scene with editor inspector buttons; GUT automated tests optional for v1

**Target Platform**: Godot Editor (Linux/Windows/Mac); generated dungeons runtime-compatible with GL Compatibility renderer

**Project Type**: Godot Editor Plugin

**Performance Goals**: Generation completes within 3s for 5 rooms, 5s for 30 rooms (per SC-001, SC-004); editor viewport updates without stalling

**Constraints**: All logic MUST run in-memory before SceneTree instantiation (Constitution II); static typing on all variables/functions; English-only committed content; `@tool` for all editor-facing nodes

**Scale/Scope**: Single plugin with 4 custom classes (DungeonConfig, RoomData, RoomConnector3D, DungeonGenerator3D) + core algorithm; ~20 GDScript files; 1 demo scene

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. GDScript + Static Typing + @tool | PASS | Spec FR-006 mandates @tool; constitution mandates static typing; project.godot confirms GDScript |
| II. Core Logic Separation | PASS | FR-001/002 require in-memory graph + AABB before instantiation; DungeonLayout entity models the pre-instantiation result |
| III. Signal-Driven Architecture | PASS | FR-008 (generation_completed) and FR-009 (generation_failed) use signals |
| IV. Graph-Based Spatial Reasoning | PASS | FR-001 (AABB overlap), FR-002 (path validation), FR-014 (backtracking) enforce graph-based spatial logic |
| V. Resource-Driven Configuration | PASS | DungeonConfig and RoomData are serializable Resource classes; FR-010 mandates single config asset |

| Constraint | Status | Evidence |
|------------|--------|----------|
| GDScript exclusively | PASS | project.godot, constitution |
| Godot 4.6 + GL Compatibility | PASS | project.godot |
| Jolt Physics | N/A | Plugin does not use physics |
| Plugin isolation (path) | **NEEDS JUSTIFICATION** | Constitution says `addons/DungeonCrawler3D/`; spec clarifies `plugins/` directory. See Complexity Tracking below. |
| Static typing | PASS | Enforced by constitution |
| Documentation language (English) | PASS | All committed files in English |

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Plugin path `plugins/` vs constitution's `addons/DungeonCrawler3D/` | The repository root is a Godot testbed project. Godot convention places editor plugins under `addons/` in the consuming project, but placing the plugin source directly there couples testbed and plugin, complicating reuse. A separate `plugins/` directory at repo root keeps the plugin self-contained and importable into any Godot project. The testbed consumes it via symlink or local addon reference. | Placing plugin under `addons/` inside the testbed mixes plugin source with consuming project, making extraction for distribution harder. A standalone repo for the plugin alone was rejected because the testbed provides essential development feedback. **Constitution amendment needed**: update "Plugin isolation" constraint from `addons/DungeonCrawler3D/` to `plugins/`. |

## Project Structure

### Documentation (this feature)

```text
specs/001-procedural-dungeon-generator/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── generator-api.md # Public interface contract
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
dungeon-crawler-3d/
├── project.godot                    # Godot testbed project
├── demo/
│   └── demo_dungeon.tscn            # Demo scene exercising the generator
├── plugins/
│   └── dungeon_crawler_3d/
│       ├── plugin.cfg               # Godot plugin metadata
│       ├── dungeon_crawler_3d.gd    # EditorPlugin entry point
│       ├── resources/
│       │   ├── dungeon_config.gd    # DungeonConfig Resource class
│       │   └── room_data.gd         # RoomData Resource class
│       ├── nodes/
│       │   ├── dungeon_generator_3d.gd  # DungeonGenerator3D custom node
│       │   └── room_connector_3d.gd    # RoomConnector3D custom node
│       └── core/
│           ├── dungeon_builder.gd   # Abstract generation algorithm
│           ├── dungeon_graph.gd     # Graph data structure
│           ├── aabb_collision.gd    # AABB overlap detection
│           └── path_validator.gd    # Start-to-boss path validation
└── specs/                           # Feature specifications (this tree)
```

**Structure Decision**: Single Godot project at repo root serving as testbed. Plugin source isolated in `plugins/dungeon_crawler_3d/` mirroring Godot's `addons/` convention but kept separate from the testbed. The testbed's `project.godot` references the plugin locally. Core algorithm classes live in `core/`, decoupled from the SceneTree per Constitution II.
