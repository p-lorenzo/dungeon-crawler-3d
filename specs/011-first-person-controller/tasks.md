# Tasks: First-Person Controller for Demo

**Input**: Design documents from `/specs/011-first-person-controller/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are included under `demo/` and run via command line.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Paths assume single project under repository root: `demo/` and `plugins/dungeon_crawler_3d/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create player directory structure under `demo/player/`
- [x] T002 [P] Initialize player-related scene configuration and files

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 Hollow out entrance room scene `demo/rooms/entrance.tscn` and configure colliders
- [x] T004 Hollow out corridor room scene `demo/rooms/corridor.tscn` and configure colliders
- [x] T005 Hollow out junction room scene `demo/rooms/junction.tscn` and configure colliders
- [x] T006 Hollow out dead end room scene `demo/rooms/dead_end.tscn` and configure colliders
- [x] T007 Hollow out boss room scene `demo/rooms/boss.tscn` and configure colliders

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Explore Dungeons in First-Person (Priority: P1) 🎯 MVP

**Goal**: Spawn as a first-person character in the generated dungeon and walk around using standard controls.

**Independent Test**: Verify that running the demo scene instantiates the player at the entrance room placement coordinates.

### Implementation for User Story 1

- [x] T008 [P] [US1] Create player controller script with movement inputs in `demo/player/player.gd`
- [x] T009 [P] [US1] Create player controller scene with capsule collider and camera in `demo/player/player.tscn`
- [x] T010 [P] [US1] Create main demo orchestrator scene `demo/demo_main.tscn`
- [x] T011 [US1] Create main demo orchestrator script `demo/demo_main.gd` to handle generator completions
- [x] T012 [US1] Configure default main scene to `demo/demo_main.tscn` in `project.godot`

**Checkpoint**: At this point, User Story 1 is fully functional and testable independently

---

## Phase 4: User Story 2 - Collision with Dungeon Geometry (Priority: P1)

**Goal**: Ensure player slides along walls and stands on floors without falling through.

**Independent Test**: Walk into walls and verify the player is blocked.

### Implementation for User Story 2

- [x] T013 [US2] Verify player slides smoothly along walls and doorway blockers in `demo/rooms/`
- [x] T014 [US2] Create headless validation script `demo/test_player_controller_structure.gd` to test nodes and static types

**Checkpoint**: At this point, User Stories 1 and 2 work together independently

---

## Phase 5: User Story 3 - Mouse Capture and Cursor Lock Toggle (Priority: P2)

**Goal**: Capture mouse cursor on click and release it on Escape.

**Independent Test**: Click viewport to lock mouse, press ESC to unlock.

### Implementation for User Story 3

- [x] T015 [US3] Implement mouse capture input mapping and Escape release toggle in `demo/player/player.gd`
- [x] T016 [US3] Design and build HUD UI overlay in `demo/demo_main.tscn` showing control instructions and status

**Checkpoint**: All user stories are now independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T017 [P] Run headless verification test suites `demo/test_player_controller_structure.gd` and `demo/test_doorway_blockers.gd`
- [x] T018 Document first-person controller implementation details in `specs/011-first-person-controller/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2)
- **User Story 2 (P2)**: Can start after Foundational (Phase 2)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2)

---

## Parallel Example: User Story 1

```bash
# Launch player controller script and scene tasks together:
Task: "Create player controller script in demo/player/player.gd"
Task: "Create player controller scene in demo/player/player.tscn"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently

### Incremental Delivery

1. Complete Setup + Foundational -> Foundation ready
2. Add User Story 1 -> Test independently -> Deploy/Demo (MVP!)
3. Add User Story 2 -> Test independently -> Deploy/Demo
4. Add User Story 3 -> Test independently -> Deploy/Demo
