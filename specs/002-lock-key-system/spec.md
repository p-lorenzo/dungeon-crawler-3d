# Feature Specification: Lock & Key Puzzle System

**Feature Branch**: `002-lock-key-system`

**Created**: 2026-06-18

**Status**: COMPLETE

**Input**: User description: "specs/proposals/002-lock-and-key-system.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Puzzle Component Configuration (Priority: P1)

Dungeon designers can visually place key spawn points in room scenes and configure room transitions as locked doors in the editor without writing code.

**Why this priority**: It is the foundation of the lock-and-key workflow, enabling designers to author puzzle layouts directly in the Godot inspector.

**Independent Test**: Can be fully tested by creating a test Room scene with a `KeySpawnPoint3D` node and another Room scene with a locked `RoomConnector3D` node, inspecting their properties in the editor.

**Acceptance Scenarios**:

1. **Given** a new or existing Room scene in the editor, **When** a designer adds a `KeySpawnPoint3D` node to it, **Then** they can view and configure a `key_id` string property in the Inspector.
2. **Given** a room scene with a `RoomConnector3D` node, **When** a designer selects the node, **Then** they can toggle a boolean `is_locked` property and assign a matching `key_id` string in the Inspector.

---

### User Story 2 - Topological Key Allocation (Priority: P1)

The generator automatically analyzes the dungeon layout, identifies locked doors, and places keys in predecessor rooms that are reachable before the player encounters those doors, preventing soft-locks.

**Why this priority**: Core logic that guarantees dungeon puzzle solvability and prevents unplayable/soft-locked layouts.

**Independent Test**: Generate a dungeon layout with a locked connector and verify that the corresponding key is assigned to a spawn point in a room reachable prior to reaching the locked connector.

**Acceptance Scenarios**:

1. **Given** a generated dungeon graph with a single locked door requiring key "red_key", **When** the allocation algorithm runs, **Then** it identifies all predecessor rooms reachable from the entrance without crossing the locked door and assigns the "red_key" to a `KeySpawnPoint3D` within one of those predecessor rooms.
2. **Given** a generated dungeon with a lock chain (Door A requires Key A, and Door B requires Key B, which is located behind Door A), **When** keys are allocated, **Then** Key A is placed in a room reachable before Door A, and Key B is placed in a room reachable after opening Door A but before Door B.

---

### User Story 3 - Dynamic Door and Key Instantiation (Priority: P2)

When the dungeon is instantiated in 3D, the system automatically swaps regular doorways for locked door actors and spawns physical key items in their designated container rooms.

**Why this priority**: Connects the in-memory generation logic to the actual game world assets and visual gameplay.

**Independent Test**: Run a test generation in the demo scene and verify that the 3D meshes for the locked door and key item are instantiated correctly in the world.

**Acceptance Scenarios**:

1. **Given** a post-processed dungeon with a registered lock-key pairing, **When** the room scenes are instantiated, **Then** the locked doorway connector instantiates a locked door actor instead of a default archway.
2. **Given** a post-processed dungeon, **When** a room containing a selected key spawn point is instantiated, **Then** the key item actor is spawned at the exact transform of the designated `KeySpawnPoint3D` node.

---

### Edge Cases

- **No Key Spawn Points**: What happens if the generator places a locked door but none of the predecessor rooms contain any `KeySpawnPoint3D` nodes?
- **Lock Bypass Paths**: How does the system handle layouts where a locked door can be bypassed via alternative open corridors? The key must still be placed, but the solver should recognize the shortcut.
- **Unsolvable Layout Loops**: How does the system handle circular room paths where a locked door blocks all routes to the predecessor rooms of another locked door?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a custom `KeySpawnPoint3D` node subclassing `Node3D` to mark potential key item spawn locations.
- **FR-002**: The `RoomConnector3D` node MUST support lock configuration, exposing editor properties to toggle locks and specify key identifiers.
- **FR-003**: The key-lock layout processing MUST execute in memory after the topological graph layout is generated but before spatial room instantiation.
- **FR-004**: The graph traversal logic MUST support backtracking from a locked doorway connector to the entrance to determine the set of all predecessor rooms.
- **FR-005**: The key assignment logic MUST pair each locked door with exactly one key spawned at a valid predecessor spawn point.
- **FR-006**: During dungeon instantiation, the generator MUST swap regular door meshes/actors with locked door actors and instantiate the key items at the selected spawn point transforms.
- **FR-007**: System MUST handle multiple doors with the same Key ID by spawning one unique key item instance per locked door. Unlocking a door consumes the key from the player's inventory, and the generator must guarantee a 1:1 match of key item instances to locked doors of that key type.
- **FR-008**: System MUST handle the absence of available predecessor key spawn points by treating it as a generation failure, triggering an exhaustive generation rollback (discarding the layout and retrying with a new seed).
- **FR-009**: System MUST select the key spawn point from predecessor rooms using an exploration-based strategy that prefers placing the key further away from the door/entrance (e.g., prioritizing dead-end rooms or rooms with the largest topological distance from the entrance/start room).

### Key Entities *(include if feature involves data)*

- **KeySpawnPoint3D**: A custom `Node3D` (using `@tool`) placed inside room scenes representing a target location for spawning key items.
  - Attributes: `key_id: String`
- **RoomConnector3D**: An upgraded custom spatial node representing room transitions.
  - Attributes: `is_locked: bool`, `key_id: String`
- **KeyLockAssignment**: A data structure mapping a specific locked `RoomConnector3D` node instance to a specific `KeySpawnPoint3D` node instance.
  - Attributes: `connector_index: int`, `spawn_point_path: NodePath`, `key_id: String`
- **KeyLockManager**: A core logic helper class (extending `RefCounted`) responsible for backtracking paths, validating reachability, and matching keys to spawn points in memory.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successfully generated dungeons with locked doors must be solvable (i.e. a path exists from start to exit that does not require crossing any locked door before its corresponding key is reachable).
- **SC-002**: The `KeyLockManager` post-processing must execute in under 15ms for dungeons of up to 50 rooms containing up to 5 locked doors.
- **SC-003**: In-editor previews using `@tool` must reflect the lock configuration status on room connector gizmos/gizmo colors immediately when toggled.
- **SC-004**: Zero key items may spawn in rooms that are only reachable by passing through the locked door that the key is intended to open.

## Assumptions

- Each unique `key_id` configuration corresponds to a matching locked gate.
- The player can inventory keys and automatically consume them when interacting with a matching locked door.
- Dungeon layouts are modeled as a connected graph of rooms where connectors define paths between nodes.
- Rooms are generated and placed statically; dynamic dungeon layout changes during play are out of scope.
