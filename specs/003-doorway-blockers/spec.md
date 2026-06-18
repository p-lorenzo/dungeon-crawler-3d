# Feature Specification: Doorway Blocker & Prefab Adapters

**Feature Branch**: `003-doorway-blockers`

**Created**: 2026-06-18

**Status**: Draft

**Input**: User description: "specs/proposals/003-doorway-blocker-adapters.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Designer Configures Doorway and Blocker Scenes (Priority: P1)

Dungeon designers can assign specific PackedScene assets to each `RoomConnector3D` node in the inspector, determining what spawns when a doorway is connected or blocked.

**Why this priority**: It is the direct configuration layer allowing designers to associate modular art assets (like walls or door frames) with generator logic.

**Independent Test**: Create a Room scene, select a `RoomConnector3D` node, and verify that the Inspector exposes `doorway_scene` and `blocker_scene` PackedScene exports.

**Acceptance Scenarios**:

1. **Given** a Room scene containing a `RoomConnector3D` node, **When** a designer views the Inspector, **Then** they see export variables named `doorway_scene` and `blocker_scene`.
2. **Given** a selected `RoomConnector3D` node, **When** a designer assigns a `.tscn` mesh scene to either slot, **Then** the Inspector serializes the PackedScene reference into the room scene file.

---

### User Story 2 - Automated Blocker/Doorway Spawning at Runtime (Priority: P1)

When instantiating the generated dungeon, the generator checks if each room connector matches an edge in the layout graph, spawning either a doorway arch or a blocker wall to seal the room.

**Why this priority**: Core layout rendering logic that ensures dungeons do not have gaping holes leading to empty void space.

**Independent Test**: Generate a dungeon layout and check that every unused room connector has the blocker scene instantiated, while connected room connectors have the doorway scene instantiated.

**Acceptance Scenarios**:

1. **Given** a room connector that does not connect to any other room (leads to void), **When** the room is instantiated in the scene tree, **Then** the `blocker_scene` asset is spawned as a child of the connector and aligned to its transform.
2. **Given** two room connectors that form an active connection in the final layout, **When** the rooms are instantiated in the scene tree, **Then** the `doorway_scene` asset is spawned to represent the open gateway.

---

### Edge Cases

- **Empty Scene Slots**: What happens if the designer leaves `doorway_scene` or `blocker_scene` blank?
- **Redundant Spawning**: How does the system handle spawning at active connections since two matching connectors from opposite rooms face each other?
- **Physics/Collision Gaps**: Do blocker walls correctly block the player's movement and vision, preventing them from walking or looking into the void?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `RoomConnector3D` node class MUST export `doorway_scene` and `blocker_scene` as `PackedScene` properties.
- **FR-002**: During room instantiation in `DungeonGenerator3D._instantiate_rooms()`, the generator MUST scan each room scene instance for children of type `RoomConnector3D`.
- **FR-003**: The generator MUST query the `DungeonGraph` to check if a connector's coordinate and alignment corresponds to an active room connection.
- **FR-004**: The system MUST instantiate the sub-scene at the connector's local transform so it inherits the translation, rotation, and scale of the connector.
- **FR-005**: The system MUST support standard, boss, and customized connector types with separate scene bindings.
- **FR-006**: To prevent visual overlap and redundant nodes at active connections, the system MUST instantiate the `doorway_scene` on only one of the two connected `RoomConnector3D` nodes (specifically, the connector belonging to the room with the lower node index in the `DungeonGraph`), leaving the matching opposite connector empty.
- **FR-007**: System MUST handle null doorway or blocker scene configurations by logging a warning in the editor and console, and leaving the slot empty (spawning nothing).
- **FR-008**: System MUST handle blocker physics/collision setup by assuming that the PackedScene is self-contained and contains all necessary StaticBody3D and CollisionShape3D nodes, instantiating the PackedScene as-is without modifying physics nodes.

### Key Entities *(include if feature involves data)*

- **RoomConnector3D**: A custom `@tool` node representing a potential transition point in a room scene layout.
  - Attributes: `connector_type: String`, `doorway_scene: PackedScene`, `blocker_scene: PackedScene`
- **DungeonGenerator3D**: The central coordinator node that builds the spatial dungeon layout and triggers dynamic door/blocker attachment.
- **DungeonGraph**: The underlying graph modeling the dungeon's room nodes and active connector links (edges).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of unused connectors in generated dungeons must have blocker scenes successfully instantiated, leaving no visual gaps or holes to the void.
- **SC-002**: Active doorway and blocker instantiation must not exceed 0.5ms per room tile during the instantiation phase.
- **SC-003**: Instantiated doorway and blocker scenes must be correctly positioned and oriented, matching the parent connector's transform with zero translational drift.
- **SC-004**: No duplicate or overlapping doorway scenes may be spawned at the same interface boundary, ensuring clean hierarchy and optimized rendering.

## Assumptions

- Each room tile has one or more child `RoomConnector3D` nodes defining possible doorway transitions.
- A connection requires two room tiles to be adjacent, with their connectors aligned back-to-back (opposite directions).
- PackedScene files assigned to `doorway_scene` and `blocker_scene` are self-contained (i.e. they include their own materials, meshes, and script logic).
