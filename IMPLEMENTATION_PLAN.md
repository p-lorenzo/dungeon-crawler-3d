# Implementation Plan

**Generated**: 2026-06-18 | **Mode**: Ralph Loop — Planning
**Source**: `specs/001-procedural-dungeon-generator/`
**Constitution**: v1.2.0

---

## Gap Analysis Summary

### Current State

| Layer | Status | Details |
|-------|--------|---------|
| Godot project scaffold | DONE | `project.godot`, `icon.svg` exist; Jolt Physics, GL Compatibility configured |
| Specifications & Design | DONE | `spec.md`, `plan.md`, `data-model.md`, `research.md`, `contracts/`, `quickstart.md`, `tasks.md` all complete |
| Plugin directory structure | **MISSING** | `plugins/dungeon_crawler_3d/` not created |
| Plugin registration | **MISSING** | No `plugin.cfg`, no EditorPlugin entry script |
| GDScript implementation | **MISSING** | 0 of 11 planned `.gd` files exist |
| Custom Resources | **MISSING** | No `DungeonConfig`, no `RoomData` |
| Custom Nodes | **MISSING** | No `DungeonGenerator3D`, no `RoomConnector3D` |
| Core algorithm | **MISSING** | No `DungeonBuilder`, no `DungeonGraph`, no AABB collision, no path validation |
| Demo scene | **MISSING** | `demo/demo_dungeon.tscn` not created |
| Automated tests | **N/A** | Not required for v1 |

### Spec / Constitution Alignment

| Issue | Detail | Resolution |
|-------|--------|------------|
| Plugin path conflict | Constitution says `addons/DungeonCrawler3D/`; spec says `plugins/` | Plan.md "Complexity Tracking" justifies `plugins/`. Constitution amendment needed. |
| `ARCHITECTURE.md` vs `plan.md` | `ARCHITECTURE.md` references `addons/DungeonCrawler3D/`; `plan.md` settled on `plugins/dungeon_crawler_3d/` | Follow `plan.md` and `tasks.md` (use `plugins/`). Update `ARCHITECTURE.md` later. |
| Spec status | `Status: Draft` — not `Status: COMPLETE` | Spec is complete enough (all checklists pass, 9 clarifications resolved). Implementation proceeds; status can be updated post-verification. |

### Total Work Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 1: Setup | T001–T003 (3) | **Complete** |
| Phase 2: Foundational | T004–T007 (4) | **Complete** |
| Phase 3: US1 — Generate Dungeon (MVP) | T008–T015 (8) | Not started |
| Phase 4: US2 — Dungeon Topology | T016–T020 (5) | Not started |
| Phase 5: US3 — Editor Iteration | T021–T026 (6) | Not started |
| Phase 6: Polish | T027–T031 (5) | Not started |
| **Total** | **31 tasks** | **7/31 complete** |

---

## Constitution Check

*Re-verified 2026-06-18 against current codebase.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. GDScript + Static Typing + @tool | PASS | Zero code exists; all planned scripts use GDScript with static typing and `@tool` where applicable |
| II. Core Logic Separation | PASS | `DungeonLayout` is in-memory ref-counted object; AABB checks run before SceneTree instantiation; `core/` decoupled from nodes |
| III. Signal-Driven Architecture | PASS | `generation_completed` and `generation_failed` signals planned on `DungeonGenerator3D` |
| IV. Graph-Based Spatial Reasoning | PASS | `DungeonGraph` + `PathValidator` + AABB overlap + backtracking all planned |
| V. Resource-Driven Configuration | PASS | `DungeonConfig` and `RoomData` as serializable Resource subclasses with `@export` |

| Constraint | Status | Evidence |
|------------|--------|----------|
| GDScript exclusively | PASS | All planned files are `.gd` |
| Godot 4.6 + GL Compatibility | PASS | `project.godot` confirms |
| Jolt Physics | N/A | Plugin does not use physics |
| Plugin isolation (`plugins/`) | PENDING | Constitution amendment needed for `addons/` → `plugins/` change |
| Static typing | PASS | Enforced by constitution, will be checked in T030 |
| English-only committed content | PASS | All docs are English |

---

## Prioritized Task Breakdown

Tasks are ordered by dependency. Highest-priority incomplete tasks come first.

### Phase 1: Setup (No dependencies — start first)

| Priority | ID | Task | Files |
|----------|----|------|-------|
| **1** | T001 | Create plugin directory structure | `plugins/dungeon_crawler_3d/`, `plugins/dungeon_crawler_3d/resources/`, `plugins/dungeon_crawler_3d/nodes/`, `plugins/dungeon_crawler_3d/core/` |
| **2** | T002 | Create `plugin.cfg` | `plugins/dungeon_crawler_3d/plugin.cfg` |
| **3** | T003 | EditorPlugin entry script (stub) | `plugins/dungeon_crawler_3d/dungeon_crawler_3d.gd` |

### Phase 2: Foundational (Blocks ALL user stories)

| Priority | ID | Task | Files | Parallel |
|----------|----|------|-------|----------|
| **4** | T004 | `RoomCategory` enum | `plugins/dungeon_crawler_3d/resources/room_data.gd` | P |
| **5** | T005 | `RoomData` Resource class | `plugins/dungeon_crawler_3d/resources/room_data.gd` | P (same file as T004) |
| **6** | T006 | `DungeonConfig` Resource class | `plugins/dungeon_crawler_3d/resources/dungeon_config.gd` |  |
| **7** | T007 | Register resources in EditorPlugin | `plugins/dungeon_crawler_3d/dungeon_crawler_3d.gd` |  |

### Phase 3: US1 — Basic Dungeon Generation (MVP)

| Priority | ID | Task | Files | Parallel |
|----------|----|------|-------|----------|
| **8** | T008 | `RoomConnector3D` custom node | `plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd` | P |
| **9** | T009 | `AABBManager` collision detection | `plugins/dungeon_crawler_3d/core/aabb_collision.gd` | P |
| **10** | T010 | `DungeonGraph` data structure | `plugins/dungeon_crawler_3d/core/dungeon_graph.gd` | P |
| **11** | T011 | Connector matching + alignment math | `plugins/dungeon_crawler_3d/core/connector_matcher.gd` |  |
| **12** | T012 | `PathValidator` | `plugins/dungeon_crawler_3d/core/path_validator.gd` |  |
| **13** | T013 | `DungeonBuilder` — linear main path | `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` |  |
| **14** | T014 | `DungeonGenerator3D` custom node | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |  |
| **15** | T015 | Register custom types in EditorPlugin | `plugins/dungeon_crawler_3d/dungeon_crawler_3d.gd` |  |

### Phase 4: US2 — Topology Control (Branches + Backtracking)

| Priority | ID | Task | Files | Parallel |
|----------|----|------|-------|----------|
| **16** | T016 | Weighted random selection with cooldown | `plugins/dungeon_crawler_3d/core/room_selector.gd` | P |
| **17** | T017 | Branch generation in DungeonBuilder | `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` |  |
| **18** | T018 | Backtracking logic | `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` |  |
| **19** | T019 | Wire topology params + failure signal | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |  |
| **20** | T020 | Branch-count vs main-path validation | `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` |  |

### Phase 5: US3 — Editor Workflow

| Priority | ID | Task | Files | Parallel |
|----------|----|------|-------|----------|
| **21** | T021 | Inspector Generate/Clear buttons | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |  |
| **22** | T022 | `generation_completed` signal | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |  |
| **23** | T023 | `generation_failed` signal | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |  |
| **24** | T024 | Pre-generation validation | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |  |
| **25** | T025 | Create demo scene + sample config | `demo/demo_dungeon.tscn`, sample `.tres` files |  |
| **26** | T026 | E2E validation (VS-001 through VS-008) | Demo scene testing |  |

### Phase 6: Polish

| Priority | ID | Task | Files | Parallel |
|----------|----|------|-------|----------|
| **27** | T027 | Edge case handling | `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` | P |
| **28** | T028 | Safety limits enforcement | `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` | P |
| **29** | T029 | Connector count validation | `plugins/dungeon_crawler_3d/resources/room_data.gd` | P |
| **30** | T030 | Static typing audit + cleanup | All `.gd` files |  |
| **31** | T031 | Final quickstart validation run | Demo scene |  |

---

## Dependency Graph

```
Phase 1 (T001→T003)  ──┐
                        ├──▶ Phase 2 (T004→T007) ──▶ Phase 3 (T008→T015)
                        │                                    │
                        │                           Phase 4 (T016→T020)
                        │                                    │
                        │                           Phase 5 (T021→T026)
                        │                                    │
                        │                           Phase 6 (T027→T031)
                        │
                        └──▶ Constitution amendment (addons/ → plugins/)
```

### Parallel Execution Opportunities

- **T004 + T005**: Same file but distinct concerns; T005 extends T004
- **T008 + T009 + T010**: Different files, no inter-dependencies
- **T016**: Separate file, can start as Phase 3 wraps up
- **T027 + T028 + T029**: Different files/concerns, can run in parallel

---

## Verification Strategy

Follow `specs/001-procedural-dungeon-generator/quickstart.md` validation scenarios at each checkpoint:

| Checkpoint | Phase | Verification |
|------------|-------|-------------|
| After Phase 2 | Foundational | Godot Inspector can create/edit/save DungeonConfig and RoomData |
| After Phase 3 | US1 (MVP) | VS-001 (basic generation), VS-002 (connector mismatch) |
| After Phase 4 | US2 | VS-003 (branch generation), VS-005 (reproducibility) |
| After Phase 5 | US3 | VS-004 (clear/regenerate), VS-006 (performance) |
| After Phase 6 | Polish | VS-007 (missing resource), VS-008 (empty pool), full 8-scenario pass |

---

## Open Items

1. **Constitution amendment**: Update `.specify/memory/constitution.md` to change plugin isolation path from `addons/DungeonCrawler3D/` to `plugins/dungeon_crawler_3d/`
2. **ARCHITECTURE.md update**: Sync with `plan.md` — change `addons/DungeonCrawler3D/` references to `plugins/dungeon_crawler_3d/`
3. **Spec status**: Update `spec.md` from `Status: Draft` to `Status: COMPLETE` after all 31 tasks are verified
4. **Partial success signaling**: `contracts/generator-api.md` defers the partial-success contract decision; needs resolution during Phase 4/5

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Plugin path `plugins/` vs constitution's `addons/DungeonCrawler3D/` | The repository root is a Godot testbed project. Godot convention places editor plugins under `addons/` in the consuming project, but placing the plugin source directly there couples testbed and plugin, complicating reuse. A separate `plugins/` directory at repo root keeps the plugin self-contained and importable into any Godot project. | Placing plugin under `addons/` inside the testbed mixes plugin source with consuming project, making extraction for distribution harder. A standalone repo for the plugin alone was rejected because the testbed provides essential development feedback. |

*(Carried forward from `specs/001-procedural-dungeon-generator/plan.md`)*
