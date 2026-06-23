# Feature Specification: Room Culling

**Feature Branch**: `010-room-culling`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "vorrei aggiungere una feature, il room culling, configurabile a livello di dungeon. Può essere attivata o disattivata, se attiva é necessario definire un nodo secondo il quale calcolare quali stanze non vanno renderizzate, se attivo bisogna definire anche a quante stanze di distanza si vuole attivare il culling."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure Room Culling in Editor (Priority: P1)

As a dungeon designer, I want to enable or disable room culling and configure the culling distance directly from the dungeon configuration or generator properties, so that I can control performance limits for different levels.

**Why this priority**: Core configuration is required for the feature to be usable. It establishes the parameters needed by the culling system.

**Independent Test**: Can be tested in the Godot inspector by checking the properties of the DungeonConfig / DungeonGenerator3D and saving/loading them successfully.

**Acceptance Scenarios**:

1. **Given** a `DungeonConfig` resource in the Inspector, **When** checking the properties, **Then** I should see a boolean flag to enable/disable room culling (`enable_culling`) and an integer to specify the culling distance (`culling_distance`), with a default distance of 2.
2. **Given** a `DungeonGenerator3D` node in the Inspector, **When** configuring it, **Then** I should see a field to specify the target node path (`culling_target_path`) or node reference (`culling_target`) which represents the entity (e.g., Player) to track.

---

### User Story 2 - Run-time Topological Culling (Priority: P1)

As a player navigating the 3D dungeon, I want only the rooms close to me (within the defined topological distance) to be rendered, while rooms that are further away are hidden, so that the game maintains high performance and rendering efficiency.

**Why this priority**: This is the core functionality that provides the actual performance benefit.

**Independent Test**: Run the game demo, move the player through doorways, and verify that rooms further than the configured distance disappear from the scene tree visibility, and reappear as the player gets closer.

**Acceptance Scenarios**:

1. **Given** a generated dungeon with `enable_culling` set to `true` and `culling_distance` set to `2`, **When** the target node is inside the Entrance room, **Then** the Entrance room, all directly connected rooms (distance 1), and all rooms connected to those (distance 2) must be visible, while all rooms at distance 3 or more must be invisible.
2. **Given** a room culling system, **When** the target node transitions from one room to another, **Then** the visibility of the rooms must update immediately to reflect the new topological distances.

---

### User Story 3 - Dynamic Culling Target Assignment (Priority: P2)

As a developer, I want to dynamically register or update the culling target node at runtime via script, so that the culling system can adapt when the player spawns, changes character, or when a cinematic camera is active.

**Why this priority**: Crucial for actual game integration since players are usually spawned dynamically at runtime.

**Independent Test**: Set the culling target via a script after the dungeon is generated and verify that room culling starts working relative to the new target.

**Acceptance Scenarios**:

1. **Given** a generated dungeon with culling enabled but no target initially set, **When** a script sets the `culling_target` to a spawned player node, **Then** the dungeon room visibility must update to center on the player's current room.

---

### Edge Cases

- **Target Node Outside All Rooms**: If the tracking target goes outside all room bounding boxes (e.g., during spawning, teleporting, falling off map, or using noclip), the system should retain the last known room's culling state to prevent all rooms from turning black instantly. If no last known room exists, it should fall back to showing all rooms.
- **Disconnected Rooms / Portals**: If the dungeon layout contains disconnected graphs (though validation usually prevents this), or if rooms are connected via locked doors, the culling distance calculations must follow the topological connections in the graph, treating locked doors as connections unless specified.
- **Multiple Targets**: If in the future multiple targets are needed (e.g., local co-op), the current scope is bounded to a single target. The single target must be handled robustly without crashing if it becomes null (e.g. if the player dies and is freed).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `DungeonConfig` MUST include the configuration properties:
  - `enable_culling: bool` (default: `false`)
  - `culling_distance: int` (default: `2`, minimum: `1`)
- **FR-002**: `DungeonGenerator3D` MUST expose a way to define the tracking target node (e.g., player or camera) via `@export var culling_target_path: NodePath` and a runtime property `culling_target: Node3D`.
- **FR-003**: The culling system MUST determine the tracker's current room by checking if the target's global 3D position is within the world-space bounding box (AABB) of each instantiated room.
- **FR-004**: The culling system MUST compute topological distances (number of room-to-room edges) from the current room to all other rooms using the active dungeon connectivity graph (`DungeonGraph`).
- **FR-005**: If culling is enabled, rooms with a topological distance less than or equal to `culling_distance` MUST have their visibility set to `true` (i.e. `visible = true`). Rooms with a distance greater than `culling_distance` MUST have their visibility set to `false`.
- **FR-006**: When `culling_target` becomes null or is invalid, the culling system MUST either show all rooms or print a warning and suspend updates, maintaining the last known valid state.
- **FR-007**: To ensure performance, the current room detection and visibility update calculations MUST be optimized, only updating when the target moves to a different room, or throttled to run at a configurable interval (e.g., every 0.1 seconds) instead of every frame.
- **FR-008**: The culling visibility changes MUST not destroy or remove nodes from the Godot SceneTree; they must only toggle their visibility (`visible` property).

### Key Entities *(include if feature involves data)*

- **DungeonConfig**: Exposes `enable_culling` and `culling_distance` as serializable parameters.
- **DungeonGraph**: The structural representation of the dungeon layout, used to calculate shortest paths (topological distance) between rooms.
- **DungeonGenerator3D**: Instantiates the dungeon, holds the active graph, and runs/updates the runtime culling logic based on the `culling_target`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Setting a room to invisible correctly hides it, reducing Godot draw calls (vertices/indices drawn) for culled rooms.
- **SC-002**: Culling updates should take less than `1.0ms` of CPU time per update, even in dungeons with up to 50 rooms.
- **SC-003**: The culling target transition from one room to another should show/hide rooms within `1` frame of the room change being detected.
- **SC-004**: Hiding/showing rooms should not trigger physics collisions rebuilds or cause hiccups (frame drops) during gameplay.

## Assumptions

- **A-001**: Rooms are bounded by AABBs which are calculated correctly during generation (pre-calculated or retrieved from the room scenes).
- **A-002**: Topological distance is based on doorway connections represented as edges in `DungeonGraph`.
- **A-003**: Culling is only executed when running the game, and is disabled by default in the Godot Editor to allow easy viewing of the full dungeon, unless an explicit editor preview flag is added.
