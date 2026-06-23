# Tasks: Room Connector Editor Gizmos

**Input**: Design documents from `/specs/008-room-connector-gizmo/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Programmatic verification tests are defined in the Polish phase.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Plugin Source**: `plugins/dungeon_crawler_3d/` at repository root
- **Demo / Tests**: `demo/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Verify existing project structure and registration files for Dungeon Crawler 3D editor plugin in plugins/dungeon_crawler_3d/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 Add exported properties aperture_width and aperture_height with clamping setters to plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd
- [x] T003 Create RoomConnectorGizmoPlugin skeleton class extending EditorNode3DGizmoPlugin in plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd
- [x] T004 Update dungeon_crawler_3d.gd to register and unregister RoomConnectorGizmoPlugin in plugins/dungeon_crawler_3d/dungeon_crawler_3d.gd

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Visualizing RoomConnector3D Apertures (Priority: P1) 🎯 MVP

**Goal**: Render the rectangular wireframe portal outline centered horizontally on the local X-axis and standing on the local floor.

**Independent Test**:
In the Godot editor, select a `RoomConnector3D` node in a scene. Verify that a rectangular outline is rendered, and verify that modifying the width or height in the Inspector resizes the rectangle instantly.

### Implementation for User Story 1

- [x] T005 Define line vertices for the rectangular aperture frame in plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd
- [x] T006 Create gizmo line material and implement _redraw to render the rectangular frame in plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd

**Checkpoint**: At this point, the rectangular portal outline should render and resize dynamically.

---

## Phase 4: User Story 2 - Visualizing Connection/Exit Direction (Priority: P1)

**Goal**: Render a directional arrow pointing along the local +Z axis representing the exit direction.

**Independent Test**:
Select a `RoomConnector3D` node. Verify that a directional arrow is visible pointing along +Z. Rotate the node and verify that the arrow rotates with it.

### Implementation for User Story 2

- [x] T007 Define line vertices for the directional exit arrow pointing along the local +Z axis in plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd
- [x] T008 Update _redraw to render the directional arrow in plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd

**Checkpoint**: At this point, both the rectangular aperture and the exit direction arrow render correctly.

---

## Phase 5: User Story 3 - Dynamic Gizmo Color Coding (Priority: P2)

**Goal**: Dynamically color-code the outline/arrow based on connection type and lock status.

**Independent Test**:
Select a `RoomConnector3D` node. Change its `connection_type` (e.g. standard_door, large_gate) and toggle `is_locked`. Verify that the gizmo colors update immediately to match the expected colors.

### Implementation for User Story 3

- [x] T009 Update _redraw to query _get_gizmo_color and draw lines with the active color in plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd

**Checkpoint**: All user stories are functionally implemented.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Verification and validation tasks

- [x] T010 [P] Implement programmatic verification test script in demo/test_room_connector_gizmo.gd
- [x] T011 Run programmatic test suite headlessly via demo/test_room_connector_gizmo.gd
- [x] T012 Run quickstart.md validation visually in the editor using demo scenes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion. BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion.
- **User Story 2 (Phase 4)**: Depends on User Story 1. (Arrow is drawn relative to the frame base).
- **User Story 3 (Phase 5)**: Depends on User Story 2. (Applies coloring to both frame and arrow).
- **Polish (Phase 6)**: Depends on all user stories being complete.

### Parallel Opportunities

- All Polish verification tasks marked [P] can run in parallel with visual validation.
- Coding structure check and setup (Phase 1) can run immediately.

---

## Parallel Example: User Story 1 & 2 Setup

Since implementation tasks reside in the same file `plugins/dungeon_crawler_3d/nodes/room_connector_gizmo_plugin.gd`, they should be completed sequentially by a single developer. However, the test script creation can proceed in parallel:

```bash
# Launch test script implementation:
Task: "Implement programmatic verification test script in demo/test_room_connector_gizmo.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1 (Rectangular aperture representation).
4. **STOP and VALIDATE**: Verify rectangular outlines render and resize dynamically in the Godot Editor.

### Incremental Delivery

1. Foundation ready.
2. Add User Story 1 -> Test rectangular portal (MVP).
3. Add User Story 2 -> Test exit arrow.
4. Add User Story 3 -> Test color-coding dynamic updates.
5. Add Polish and Headless Tests -> Final release.
