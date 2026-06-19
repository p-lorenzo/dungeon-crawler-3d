# Tasks: Curved Dungeon Branches

**Input**: Design documents from `/specs/007-curved-dungeon-branches/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- All plugin code lives under `plugins/dungeon_crawler_3d/`
- All demo/test files live under `demo/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 [P] Create the corner room scene file `demo/rooms/corner.tscn` containing two `RoomConnector3D` nodes at a 90-degree angle.
- [ ] T002 [P] Create the T-junction room scene file `demo/rooms/t_junction.tscn` containing three `RoomConnector3D` nodes at 90-degree angles.
- [ ] T003 [P] Create the room data resources `demo/room_data/corner_data.tres` and `demo/room_data/t_junction_data.tres` pointing to their respective scenes.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core mathematical and spatial calculations in the plugin core

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Verify transform alignment calculations for 90-degree angles inside `compute_alignment_transform` in `plugins/dungeon_crawler_3d/core/connector_matcher.gd`.
- [ ] T005 [P] Update world AABB computation logic inside `_compute_room_world_aabb` in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd` to ensure rotated bounds are calculated correctly (expanding corners).

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Winding and Curved Main Path (Priority: P1) 🎯 MVP

**Goal**: Support L-shaped corner turns along the main critical path

**Independent Test**: Execute the corner room placement test case in `demo/test_curved_branches.gd`

### Tests for User Story 1

- [ ] T006 [US1] Create the integration test script `demo/test_curved_branches.gd` with a test case checking that a 90-degree corner room is successfully placed and aligned on the main path.

### Implementation for User Story 1

- [ ] T007 [US1] Implement 90-degree connector match search and alignment in `_place_path_node_recursive` inside `plugins/dungeon_crawler_3d/core/dungeon_builder.gd`.
- [ ] T008 [US1] Ensure that layout collisions (overlaps) are correctly tracked and trigger recursive backtracking inside `_place_path_node_recursive` in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd`.

**Checkpoint**: At this point, the generator supports curved main paths independently.

---

## Phase 4: User Story 2 - Curved Secondary Branches (Priority: P2)

**Goal**: Support curves and turns on side branches with recursive collision backtracking

**Independent Test**: Execute the branch backtracking test case in `demo/test_curved_branches.gd`

### Tests for User Story 2

- [ ] T009 [US2] Add an integration test case in `demo/test_curved_branches.gd` verifying that side branches turn correctly and backtrack upon hitting existing room AABBs.

### Implementation for User Story 2

- [ ] T010 [US2] Implement 90-degree connector matching and layout alignment inside `_place_branch_node_recursive` in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd`.
- [ ] T011 [US2] Add random selection among multiple exits for junction rooms and mark remaining exits as branch candidates in `plugins/dungeon_crawler_3d/core/dungeon_builder.gd`.

**Checkpoint**: Winding branches can now be generated and tested independently of other stories.

---

## Phase 5: User Story 3 - Diverse Angled Room Prefabs (Priority: P3)

**Goal**: Add visual room geometry and link corner/T-junction rooms into default demo configs

**Independent Test**: Verify layout generation via the Godot editor viewport with the default demo configuration

### Implementation for User Story 3

- [ ] T012 [P] [US3] Finalize room structural meshes, materials, and connector configurations in `demo/rooms/corner.tscn`.
- [ ] T013 [P] [US3] Finalize room structural meshes, materials, and connector configurations in `demo/rooms/t_junction.tscn`.
- [ ] T014 [US3] Add the corner and T-junction room resources to the defaults in `demo/demo_config.tres` to enable curved layouts in the editor.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and linting

- [ ] T015 Run the entire suite of integration tests headlessly using the Godot binary (including `test_curved_branches.gd` and `test_tile_injection.gd`).
- [ ] T016 Perform final GDScript formatting and static type checks across all modified files under `plugins/dungeon_crawler_3d/`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User Story 1 (P1) is the critical path MVP and should be completed first.
  - User Story 2 (P2) can be worked on in parallel with or after User Story 1.
- **Polish (Phase 6)**: Depends on all user stories being complete.

### Parallel Opportunities

- Setup tasks T001, T002, T003 can run in parallel.
- User Story 3 layout scenes T012 and T013 can be modeled in parallel.

---

## Parallel Example: User Story 3

```bash
# Model geometries and finalize scenes for both room prefabs together:
Task: "Finalize room structural meshes, materials, and connector configurations in demo/rooms/corner.tscn"
Task: "Finalize room structural meshes, materials, and connector configurations in demo/rooms/t_junction.tscn"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (T004, T005)
3. Complete Phase 3: User Story 1 (T006, T007, T008)
4. **STOP and VALIDATE**: Run `demo/test_curved_branches.gd` to verify corner turns on main path.

### Incremental Delivery

1. Complete Setup + Foundational → Core is ready.
2. Complete User Story 1 → Winding main paths working (MVP!).
3. Complete User Story 2 → Winding branch paths working.
4. Complete User Story 3 → Asset assets finalized and default config updated.
5. Polish.
