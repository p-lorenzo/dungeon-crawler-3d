# Tasks: Random Connector Selection

**Input**: Design documents from `/specs/009-random-connector-selection/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Programmatic verification tests are defined in the Polish phase.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Core Code**: `plugins/dungeon_crawler_3d/core/`
- **Demo / Tests**: `demo/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Verify existing project structure for Dungeon Crawler 3D generation logic and test script environment in plugins/dungeon_crawler_3d/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Locate _find_unused_connector() inside plugins/dungeon_crawler_3d/core/dungeon_builder.gd and verify access to the seeded RandomNumberGenerator (_rng)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Labyrinth-Like Dungeon Layouts (Priority: P1) 🎯 MVP

**Goal**: Pick a random unused connector using `_rng.randi()` in `_find_unused_connector` to enable winding and curved layout generation.

**Independent Test**:
Run the generator using a layout containing multi-exit rooms. Check that the rooms are connected along different exits (producing corners and turns), and that the layouts are reproducible.

### Implementation for User Story 1

- [x] T003 [US1] Modify _find_unused_connector() in plugins/dungeon_crawler_3d/core/dungeon_builder.gd to collect all valid unused connector indices, pick one using _rng.randi(), and return it

**Checkpoint**: Winding paths are now active.

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Verification and validation tasks

- [x] T004 [P] Implement programmatic integration test in demo/test_random_connector_selection.gd
- [x] T005 Run test suite headlessly via demo/test_random_connector_selection.gd

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion. BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion.
- **Polish (Phase 4)**: Depends on User Story 1 completion.

### Parallel Opportunities

- **T004** (writing the test script) can be started in parallel since it resides in a separate file `demo/test_random_connector_selection.gd`.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Setup & Foundational checks.
2. Implement T003 in `dungeon_builder.gd`.
3. Verify winding generation.
