# Implementation Plan

**Generated**: 2026-06-18 | **Mode**: Ralph Loop — Planning
**Source**: `specs/001-procedural-dungeon-generator/`, `specs/002-lock-key-system/`, `specs/003-doorway-blockers/`, `specs/004-prop-randomization/`, `specs/005-navmesh-baking/`
**Constitution**: v1.3.0

---

## Gap Analysis Summary

### Current State

| Layer | Status | Details |
|-------|--------|---------|
| **Godot project scaffold** | DONE | `project.godot`, `icon.svg` exist; Jolt Physics, GL Compatibility configured |
| **001: Procedural Dungeon Generator** | DONE | All 31 tasks (MVP, topology control, editor workflow, and polish) are fully implemented and verified in the demo scene. |
| **002: Lock & Key Puzzle System** | **DONE** | All 8 tasks (T032–T039) implemented, integrating KeySpawnPoint3D, locked connectors, and KeyLockManager solver. |
| **003: Doorway Blocker & Prefab Adapters** | **DONE** | All 6 tasks (T040–T045) implemented, spawning active doorway scenes on lower graph index room and blocker scenes on unused connectors. |
| **004: Prop Randomizer & Clamping** | **DONE** | All 7 tasks (T046–T052) implemented, integrating PropGroup3D, DungeonPropManager, and global limit clamping. |
| **005: NavMesh Baking Adapter** | **PLANNED** | Feature specification exists. The codebase has no adapter node to listen for generation signals and rebuild Godot's `NavigationRegion3D` paths. |

### Spec / Constitution Alignment

- **002: Lock & Key System**: Path validation backtracking must operate in-memory (using `KeyLockManager`) before instantiation to adhere to **Principle II (Core Logic Separation)**. Gizmo updates for locked states in `RoomConnector3D` are required under **Principle I (@tool visual feedback)**.
- **003: Doorway Blockers**: To satisfy the constraint of no visual overlap, the generator must only instantiate the active doorway scene on one side of a connection. We must use `DungeonGraph` index comparison to determine the spawning node.
- **004: Prop Randomizer**: Weight normalization and random selection must be seed-driven to maintain **Principle IV (Deterministic Topology)** and reproducibility. Mismatched weight arrays must fallback to uniform distribution.
- **005: NavMesh Baking**: The `DungeonNavMeshAdapter3D` must parse geometry from the dynamic level layout and trigger NavigationMesh baking. To comply with performance requirements and **Technical Constraints (Physics & Rendering performance)**, the system must support asynchronous thread-based baking. To support designer iteration, it must support synchronous main-thread baking in the editor under `@tool` to instantly update viewport navigation meshes.

### Total Work Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| Phase 1: Setup | T001–T003 (3) | **Complete** |
| Phase 2: Foundational | T004–T007 (4) | **Complete** |
| Phase 3: MVP Generator | T008–T015 (8) | **Complete** |
| Phase 4: Topology Control | T016–T020 (5) | **Complete** |
| Phase 5: Editor Workflow | T021–T026 (6) | **Complete** |
| Phase 6: Generator Polish | T027–T031 (5) | **Complete** |
| **Phase 7: Lock & Key System (002)** | T032–T039 (8) | **Complete** |
| **Phase 8: Doorway Blockers (003)** | T040–T045 (6) | **Complete** |
| **Phase 9: Prop Randomizer (004)** | T046–T052 (7) | **Complete** |
| **Phase 10: NavMesh Baking Adapter (005)** | T053–T058 (6) | **PLANNED** |
| **Phase 11: E2E & Final Verification** | T059–T061 (3) | **PLANNED** |
| **Total** | **61 tasks** | **52/61 complete** |

---

## Constitution Check

*Re-verified 2026-06-18 against planned architectures.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| **I. GDScript + Static Typing + @tool** | PASS | All new nodes (`KeySpawnPoint3D`, `PropGroup3D`, `DungeonNavMeshAdapter3D`) and classes will use static typing and `@tool`. `RoomConnector3D` updates will retain editor gizmo drawing for lock status. `DungeonNavMeshAdapter3D` bakes the NavMesh in the editor under `@tool` upon generation completion. |
| **II. Core Logic Separation** | PASS | `KeyLockManager` processes backtrack routes and allocates keys to containers in memory using a virtual layout model, with zero SceneTree dependencies. The `DungeonNavMeshAdapter3D` operates post-generation, taking the completed dungeon root Node3D to parse geometry. |
| **III. Signal-Driven Architecture** | PASS | Soft-locks and invalid puzzle configurations will trigger dedicated signals/retries in `DungeonBuilder` rather than leaking half-built levels. The navmesh adapter listens to `generation_completed` to decouple baking. |
| **IV. Graph-Based Spatial Reasoning** | PASS | Key assignment checks connectivity from the entrance to locked portals using DFS/BFS on `DungeonGraph` edges before committing to node spawning. |
| **V. Resource-Driven Configuration** | PASS | Global prop limits and key-lock variables will be managed via `DungeonConfig` serializable dictionary entries. Navigation parameters are configured via inspector exports or the target `NavigationRegion3D`'s custom resources. |

| Constraint | Status | Evidence |
|------------|--------|----------|
| **GDScript exclusively** | PASS | All planned scripts are GDScript (`.gd`). |
| **Godot 4.6 + GL Compatibility** | PASS | Enforced in `project.godot`. |
| **Plugin isolation (`plugins/`)** | PASS | All new logic remains strictly inside `plugins/dungeon_crawler_3d/`. |
| **English-only committed content** | PASS | Code and comments will remain exclusively in English. |

---

## Prioritized Task Breakdown

### Phase 1 to Phase 7 (Completed Tasks)
*Tasks T001 to T039 are complete, verified, and merged. Details omitted to focus on new phases.*


### Phase 8: Doorway Blocker & Prefab Adapters (003)

| Priority | ID | Task | Files |
|----------|----|------|-------|
| **40** | T040 | Upgrade `RoomConnector3D` to export `doorway_scene` and `blocker_scene` | `plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd` |
| **41** | T041 | Implement helper in `DungeonGraph` to query active edges for connectors | `plugins/dungeon_crawler_3d/core/dungeon_graph.gd` |
| **42** | T042 | Add active doorway spawning hook with transform inheritance | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |
| **43** | T043 | Add inactive blocker spawning hook with transform inheritance | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |
| **44** | T044 | Implement overlap filter (lower graph index door spawning rule) | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |
| **45** | T045 | Create demo scenes showing connected rooms vs blocker walls | `demo/` |

### Phase 9: Prop Randomizer & Clamping (004)

| Priority | ID | Task | Files |
|----------|----|------|-------|
| **46** | T046 | Implement `PropGroup3D` node with category/weights | `plugins/dungeon_crawler_3d/nodes/prop_group_3d.gd` |
| **47** | T047 | Upgrade `DungeonConfig` for `global_prop_limits` dictionary | `plugins/dungeon_crawler_3d/resources/dungeon_config.gd` |
| **48** | T048 | Implement `DungeonPropManager` tracking and limit clamping | `plugins/dungeon_crawler_3d/core/dungeon_prop_manager.gd` |
| **49** | T049 | Add weight normalization and fallback logic | `plugins/dungeon_crawler_3d/core/dungeon_prop_manager.gd` |
| **50** | T050 | Integrate `DungeonPropManager` hook into room instantiation | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |
| **51** | T051 | Ensure unspawned prop placeholder nodes are cleanly freed | `plugins/dungeon_crawler_3d/nodes/dungeon_generator_3d.gd` |
| **52** | T052 | Register `PropGroup3D` in `EditorPlugin` entry | `plugins/dungeon_crawler_3d/dungeon_crawler_3d.gd` |

### Phase 10: NavMesh Baking Adapter (005)

| Priority | ID | Task | Files |
|----------|----|------|-------|
| **53** | T053 | Implement `DungeonNavMeshAdapter3D` node skeleton with exported properties | `plugins/dungeon_crawler_3d/nodes/dungeon_navmesh_adapter_3d.gd` |
| **54** | T054 | Connect adapter to listen for the `generation_completed` signal from `DungeonGenerator3D` | `plugins/dungeon_crawler_3d/nodes/dungeon_navmesh_adapter_3d.gd` |
| **55** | T055 | Implement fallback for missing/unresolved navigation region | `plugins/dungeon_crawler_3d/nodes/dungeon_navmesh_adapter_3d.gd` |
| **56** | T056 | Implement synchronous vs asynchronous NavigationMesh baking | `plugins/dungeon_crawler_3d/nodes/dungeon_navmesh_adapter_3d.gd` |
| **57** | T057 | Implement editor-time viewport navigation mesh baking under `@tool` | `plugins/dungeon_crawler_3d/nodes/dungeon_navmesh_adapter_3d.gd` |
| **58** | T058 | Register `DungeonNavMeshAdapter3D` custom type in `EditorPlugin` entry | `plugins/dungeon_crawler_3d/dungeon_crawler_3d.gd` |

### Phase 11: E2E & Final Verification

| Priority | ID | Task | Files |
|----------|----|------|-------|
| **59** | T059 | Perform a comprehensive static typing audit across all new scripts | All scripts |
| **60** | T060 | Run E2E integration test suite for seed-based props, lock puzzles, and navmesh baking | `demo/` |
| **61** | T061 | Update `ARCHITECTURE.md` to reflect new modules | `ARCHITECTURE.md` |

---

## Dependency Graph

```
Phase 1–6 (T001→T031)  [Completed]
          │
          ├──▶ Phase 7: Lock & Key Puzzle System (T032→T039)
          │             │
          │             └──────────────┐
          │                            ▼
          ├──▶ Phase 8: Doorway Blockers (T040→T045)
          │             │
          │             └──────────────┐
          │                            ▼
          ├──▶ Phase 9: Prop Randomizer (T046→T052)
          │             │
          │             └──────────────┐
          │                            ▼
          └──▶ Phase 10: NavMesh Baking Adapter (T053→T058)
                        │
                        └──────────────┐
                                       ▼
                                   Phase 11: E2E Integration (T059→T061)
```

---

## Verification Strategy

### Lock & Key System (002) Checkpoints
- **Visual Validation**: Connectors with `is_locked = true` change gizmo colors to magenta/red in the editor immediately.
- **Reachability Verification**: Verify that a generated dungeon requiring "boss_key" places the key strictly in rooms preceding the boss door (relative to the entrance).
- **Soft-lock Prevention**: Configure a room to have a locked connector but no predecessor rooms with `KeySpawnPoint3D` nodes. Confirm generation fails cleanly, triggering rollbacks.

### Doorway Blocker (003) Checkpoints
- **Gap Verification**: Generate a maze layout. Check that all open connections contain exactly one active doorway actor, and all empty connectors are sealed with solid blocker wall nodes.
- **Redundancy Audit**: Inspect the node hierarchy of a completed generation; ensure there are no overlapping/duplicate doors at transition points.

### Prop Randomizer (004) Checkpoints
- **Limit Enforcement**: Set category "chests" global limit to 2 in `DungeonConfig`. Run generation and confirm no more than 2 chest scenes exist.
- **Seed Consistency**: Run generation 5 times with the same seed. Verify that both the selected props and their placement locations are identical.
- **Weights Fallback**: Configure a prop group with 3 items but only 1 weight. Verify that items spawn with uniform probability.

### NavMesh Baking Adapter (005) Checkpoints
- **Automatic Trigger**: Verify that generating a dungeon automatically starts a NavMesh bake, and `DungeonNavMeshAdapter3D` correctly targets the generated root.
- **Thread Safety (Async)**: Verify that dynamic baking doesn't block the main game thread or freeze the engine during play (async check).
- **Editor Baking**: Generate a dungeon in the Godot Editor; verify the navigation mesh is compiled and visible immediately in the 3D viewport.
- **Missing Region Fallback**: Remove the `NavigationRegion3D` node from the scene, trigger a generate, and verify the adapter spawns a new one under the dungeon layout root and bakes the mesh.

---

## Open Items (Resolutions)

1. **Weights configuration mismatch**: If a designer configures a `prop_pool` but omits `weights` (or the array length does not match), the system will treat weights as uniform (each item has equal probability).
2. **Prop cleanup**: Any `PropGroup3D` that fails its spawn chance or is skipped due to global limits will be freed from the scene using `queue_free()` during room instantiation to avoid leaving empty placeholders in the scene hierarchy.
3. **Deterministic randomness**: The `DungeonPropManager` will use the generator's global random seed (passing down the shared `RandomNumberGenerator` instance from the `DungeonBuilder`) to guarantee reproducible prop layouts.
4. **Key identification**: To allow flexibility in asset setup, `RoomConnector3D` and `KeySpawnPoint3D` will support a direct `key_id: String` identifier. During instantiation, the system maps this identifier to corresponding key/door scene variables.
5. **Editor-time threading restriction**: Editor-time baking under `@tool` will run synchronously (`on_thread = false`) to ensure editor viewports redraw immediately and avoid threading conflicts inside editor plugins.
6. **Parsing source configurations**: The adapter will modify the parsing source of the `NavigationMesh` resource to point to the instantiated dungeon root, ensuring we parse only the generated rooms.

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected |
|-----------|------------|------------------------------|
| Scanning `PackedScene` for keys in memory before instantiation | Needed to check for `KeySpawnPoint3D` nodes in predecessor rooms during layout planning to ensure unsolvable/soft-locked graphs fail and rollback before 3D instantiation occurs. | Querying the SceneTree after instantiation and then deleting/regenerating rooms is too slow and visually jarring in editor tools. We use `PackedScene.get_state()` to read nodes in memory. |
