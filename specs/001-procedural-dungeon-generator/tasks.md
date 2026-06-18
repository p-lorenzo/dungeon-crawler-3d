# Tasks: Procedural Dungeon Generator

**Input**: Design documents from `/specs/001-procedural-dungeon-generator/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Not explicitly requested in feature specification. Test tasks are omitted. Validation is performed via the demo scene (per quickstart.md / constitution).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Plugin source**: `plugins/dungeon_crawler_3d/` (Godot EditorPlugin)
- **Structure**: `plugins/dungeon_crawler_3d/resources/` (Resources), `plugins/dungeon_crawler_3d/nodes/` (Custom Nodes), `plugins/dungeon_crawler_3d/core/` (Core Logic)
- **Testbed**: `demo/` (demo scene consuming the plugin)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Plugin skeleton and registration — minimal structure so Godot recognizes the plugin.

- [x] T001 Create plugin directory structure: `plugins/dungeon_crawler_3d/`, `plugins/dungeon_crawler_3d/resources/`, `plugins/dungeon_crawler_3d/nodes/`, `plugins/dungeon_crawler_3d/core/`
- [x] T002 Create `plugins/dungeon_crawler_3d/plugin.cfg` with plugin metadata (name: "Dungeon Crawler 3D", description, author, version)
- [x] T003 Create `plugins/dungeon_crawler_3d/dungeon_crawler_3d.gd` — EditorPlugin entry script registering custom types (stub with `_enter_tree` / `_exit_tree`)

---

## Phase 2: Foundational (Data Definitions)

**Purpose**: Custom Resource classes that ALL user stories depend on. Must be complete before any generation logic.

**CRITICAL**: No user story work can begin until this phase is complete.

- [x] T004 [P] Create `RoomCategory` enum (ENTRANCE, BOSS, CORRIDOR, JUNCTION, DEAD_END) in `plugins/dungeon_crawler_3d/resources/room_data.gd`
- [x] T005 [P] Implement `RoomData` Resource class in `plugins/dungeon_crawler_3d/resources/room_data.gd` — fields: `room_scene: PackedScene`, `spawn_weight: float`, `category: int` (RoomCategory); with `@export` annotations for inspector visibility
- [x] T006 Implement `DungeonConfig` Resource class in `plugins/dungeon_crawler_3d/resources/dungeon_config.gd` — all 11 fields per data-model.md: `main_path_length`, `branch_count`, `branch_depth_min`, `branch_depth_max`, `room_count_min`, `room_count_max`, `random_seed`, `max_generation_attempts`, `entrance_pool`, `boss_pool`, `corridor_pool`, `junction_pool`, `dead_end_pool`; with `@export` annotations and validation in `_validate_property()` or init check
- [x] T007 Register DungeonConfig and RoomData as custom resources in EditorPlugin (`dungeon_crawler_3d.gd`) via `add_custom_resource_type()`

**Checkpoint**: Data definitions ready — Godot Inspector can create, edit, and save DungeonConfig and RoomData resources.

---

## Phase 3: User Story 1 - Generate a Dungeon from Room Pool (Priority: P1) — MVP

**Goal**: Produce a connected, non-overlapping dungeon with a valid entrance→exit path from a pool of compatible rooms.

**Independent Test**: Create 3 room scenes (entrance, corridor, exit) with matching connectors, assign to pools in DungeonConfig, click Generate. Verify 3 rooms appear, no overlaps, traversable path.

### Implementation for User Story 1

- [x] T008 [P] [US1] Implement `RoomConnector3D` custom node in `plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd` — extends `Node3D` with `@tool`; `@export var connection_type: String`; editor gizmo (sphere + arrow) for visibility in viewport
- [x] T009 [P] [US1] Implement `AABBManager` class in `plugins/dungeon_crawler_3d/core/aabb_collision.gd` — computes AABB from a room's PackedScene geometry; `check_overlap(aabb: AABB, placed_aabbs: Array[AABB]) -> bool`
- [x] T010 [P] [US1] Implement `DungeonGraph` class in `plugins/dungeon_crawler_3d/core/dungeon_graph.gd` — ref-counted object storing placements (RoomPlacement dicts) and edges (ConnectorPair dicts) per data-model.md; methods: `add_placement()`, `add_edge()`, `get_path()`
- [x] T011 [US1] Implement connector matching logic in `plugins/dungeon_crawler_3d/core/connector_matcher.gd` — function `find_matching_connector(candidate_room: RoomData, target_connector_type: String) -> int` (returns connector index or -1); free-alignment transform calculator `compute_alignment_transform(connector_a: Transform3D, connector_b: Transform3D) -> Transform3D`
- [x] T012 [US1] Implement `PathValidator` class in `plugins/dungeon_crawler_3d/core/path_validator.gd` — `validate_path(graph: DungeonGraph) -> bool` traverses from entrance to boss confirming connectivity
- [x] T013 [US1] Implement `DungeonBuilder` class in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` — generates a linear main path (no branches yet): selects entrance room → iteratively matches connectors → places corridor rooms → places boss room; produces a `DungeonLayout` (in-memory, per data-model.md) with AABB checks at each step; accepts DungeonConfig as input
- [x] T014 [US1] Implement `DungeonGenerator3D` custom node in `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` — extends `Node3D` with `@tool`; `@export var config: DungeonConfig`; `generate()` method: calls DungeonBuilder, instantiates resulting room PackedScenes as children with computed transforms, sets `owner` for packed scene serialization; `clear()` method: frees all generated children
- [x] T015 [US1] Register RoomConnector3D and DungeonGenerator3D as custom types in EditorPlugin (`dungeon_crawler_3d.gd`) via `add_custom_type()`

**Checkpoint**: Linear dungeon generation functional — entrance→corridor(s)→boss path works in editor without branches.

---

## Phase 4: User Story 2 - Configure Dungeon Topology (Priority: P2)

**Goal**: Designer controls branch count, branch depth range, and the generator produces dungeons respecting these topology constraints.

**Independent Test**: Configure main_path_length=5, branch_count=2, branch_depth_min=1, branch_depth_max=3. Generate 10 dungeons. Verify exactly 2 branches per dungeon, each 1-3 rooms deep.

### Implementation for User Story 2

- [x] T016 [P] [US2] Implement weighted random selection with cooldown in `plugins/dungeon_crawler_3d/core/room_selector.gd` — function `select_weighted(pool: Array[RoomData], recent_rooms: Array[RoomData], rng: RandomNumberGenerator) -> RoomData` using cumulative distribution + recent-room penalty per research.md
- [x] T017 [US2] Extend `DungeonBuilder` in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` — add branch generation: after main path is placed, iterate branch_count times; for each branch, pick a random main-path room as attachment point, select branch rooms from corridor/junction/dead_end pools respecting branch_depth_min/max range; integrate weighted room selector (T016); ensure branches terminate in dead-end rooms
- [x] T018 [US2] Implement backtracking logic in `DungeonBuilder` in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` — when no valid room candidate fits a slot, pop the last placement and try the next candidate (1-step backtrack); repeat up to `max_generation_attempts` per position; signal failure if exhausted
- [x] T019 [US2] Extend `DungeonGenerator3D` in `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` — wire topology parameters from DungeonConfig into DungeonBuilder; implement `clear()` if not already done in T014; add `generation_failed(reason: String)` signal emission on builder failure
- [x] T020 [US2] Add branch-count vs main-path-rooms validation in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` — if `branch_count > main_path_length`, place one branch per available room and emit a partial-success note in the signal/metadata

**Checkpoint**: Full topology generation — dungeons with controllable branches, depth range, weighted selection, backtracking.

---

## Phase 5: User Story 3 - Iterate in the Editor Without Running the Game (Priority: P3)

**Goal**: Designer clicks Generate/Clear in the inspector, sees results in the viewport instantly, tweaks parameters, regenerates — all without pressing Play.

**Independent Test**: Open demo scene, change a topology param, click Generate, verify viewport updates within 2 seconds. Repeat 5 times with different parameters.

### Implementation for User Story 3

- [x] T021 [US3] Add inspector buttons to `DungeonGenerator3D` in `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` — `@export var _generate_button: bool` setter triggers `generate()`; `@export var _clear_button: bool` setter triggers `clear()`; use `@export_category("Actions")` for inspector grouping
- [x] T022 [US3] Implement `generation_completed(dungeon_root: Node3D)` signal on `DungeonGenerator3D` — emitted after all rooms are instantiated and validated; per contracts/generator-api.md
- [x] T023 [US3] Implement `generation_failed(reason: String)` signal on `DungeonGenerator3D` — emitted on any failure with human-readable reason; wire all failure paths from DungeonBuilder through to this signal
- [x] T024 [US3] Add pre-generation validation in `DungeonGenerator3D` — check `config != null`, pools non-empty, entrance/boss pools non-empty, PackedScene references valid; emit `generation_failed` for each detected issue BEFORE any rooms are placed
- [x] T025 [US3] Create demo scene `demo/demo_dungeon.tscn` — add a `DungeonGenerator3D` node; create a sample `DungeonConfig` resource (demo_config.tres) with 5 sample RoomData entries; assign config to generator
- [x] T026 [US3] End-to-end validation: follow all 8 quickstart.md validation scenarios (VS-001 through VS-008) in the demo scene; fix any issues found

**Checkpoint**: Full editor workflow — Generate/Clear buttons, signals, demo scene, all validation scenarios passing.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, error handling, and cleanup.

- [x] T027 [P] Add edge case handling in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` — empty pool detection, incompatible connector types, unsatisfiable room count, missing PackedScene reference detection; all produce clear error strings for `generation_failed`
- [x] T028 [P] Add safety limits enforcement in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` — enforce `room_count_max` as hard cap; enforce `branch_depth_max` as per-branch limit; prevent infinite loops via `max_generation_attempts` per position
- [x] T029 [P] Add connector count validation on RoomData — DEAD_END rooms must have at least 1 connector; warn if room has 0 connectors
- [x] T030 Clean up code — ensure all files use static typing (`var timer: Timer`, `func generate() -> void:`), consistent naming, remove debug prints
- [x] T031 Run through VS-001 through VS-008 quickstart validation one final time; document results

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on T001 (directory structure) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion
- **User Story 2 (Phase 4)**: Depends on US1 completion (extends DungeonBuilder, DungeonGenerator3D)
- **User Story 3 (Phase 5)**: Depends on US2 completion (signals + buttons wire into full generator)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational (Phase 2) — no dependencies on other stories
- **US2 (P2)**: Depends on US1 (extends DungeonBuilder's linear path to add branches; extends DungeonGenerator3D)
- **US3 (P3)**: Depends on US2 (signals, buttons, demo scene require full generator functionality)

### Within Each User Story

- Core utility classes (graph, AABB, connector matcher) before DungeonBuilder
- DungeonBuilder before DungeonGenerator3D
- Basic implementation before integration

### Parallel Opportunities

- T004, T005 can run in parallel (different concerns in same file — T005 builds on T004)
- T008, T009, T010 in US1 can run in parallel (different files, no dependencies)
- T016 in US2 can start in parallel with US1 completion (separate file)
- T027, T028, T029 in Polish can run in parallel (different concerns)

---

## Parallel Example: User Story 1

```bash
# Launch core utility classes together (different files, no inter-dependencies):
Task: "Implement AABBManager in plugins/dungeon_crawler_3d/core/aabb_collision.gd"
Task: "Implement DungeonGraph in plugins/dungeon_crawler_3d/core/dungeon_graph.gd"
Task: "Implement RoomConnector3D in plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd"

# Then sequential:
Task: "Implement connector_matcher.gd" (needs connector model from T008)
Task: "Implement path_validator.gd" (needs DungeonGraph from T010)
Task: "Implement DungeonBuilder.gd" (needs AABB, connector_matcher, graph, path_validator)
Task: "Implement DungeonGenerator3D.gd" (needs DungeonBuilder)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Open demo scene, generate a linear dungeon, verify entrance→boss path
5. MVP is shippable — a working dungeon generator with basic functionality

### Incremental Delivery

1. Setup + Foundational → Godot recognizes plugin, Inspector can create configs
2. Add US1 → Linear dungeon generation works → MVP!
3. Add US2 → Branches, backtracking, topology control → Full generator
4. Add US3 → Editor buttons, signals, demo scene → Complete product
5. Each story adds value without breaking previous functionality

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Constitution compliance: all code in GDScript with static typing, @tool on editor nodes, core logic in-memory before SceneTree, signals for communication
- Path `plugins/` per spec clarification (constitution amendment pending for addons/ → plugins/ change)
- No test tasks generated — tests not requested in spec; validation via demo scene and quickstart.md scenarios
- Commit after each task or logical group for clean history
