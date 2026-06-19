# Feature Specification: Curved Dungeon Branches

**Feature Branch**: `007-curved-dungeon-branches`

**Created**: 2026-06-18

**Status**: Draft

**Input**: User description: "Adesso come adesso il main branch e i secondary branch generati sono sempre dritti, dobbiamo modificare l'algoritmo di generazione in modo che i branch creati sia il main che secondaries, possano essere anche non dritti ma avere curve grazie a stanze con connector non uno di fronte all'altro, oltre che aggiustare l'algoritmo di generazione, creiamo svariate stanze con più porte a diverse angolazioni."

## Clarifications

### Session 2026-06-18

- Q: Do we restrict aligned turns to 90-degree increments, or do we need to support arbitrary angles? → A: Restrict turns strictly to 90-degree increments (0, 90, 180, 270 degrees).
- Q: How do we calculate the axis-aligned bounding box (AABB) of a room rotated by 90 or 270 degrees? → A: Swap local X and Z dimensions of the unrotated AABB for 90/270 degree rotations to keep bounding boxes tight and axis-aligned.
- Q: How are multiple exit doors in curved/junction rooms handled during generation? → A: Select one exit at random to continue the path; expose others for potential side branches; block remaining unused exits.
- Q: Are vertical paths or loops/cycles in scope? → A: Both vertical paths (stairs/multi-floor) and graph loops (cycles) are explicitly declared out of scope.
- Q: Should the builder prioritize straight corridors over curved rooms? → A: Purely determined by designer-defined `spawn_weight` in the room resource pools.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Winding and Curved Main Path (Priority: P1)

As a dungeon designer, I want the generation algorithm to support rooms with non-opposing connector angles (e.g. 90-degree turn corridors/corners) on the main path, so that the generated level has curves and turns instead of being a single straight line.

**Why this priority**: Winding main paths are the core requirement of this feature. Without it, the player cannot traverse a curved dungeon.

**Independent Test**: Configure a main path length of 5. Include a 90-degree corner room in the corridor pool. Trigger generation and verify that the rooms align correctly along the 90-degree turn without gaps or overlapping geometry, and that the path remains fully traversable.

**Acceptance Scenarios**:

1. **Given** a corridor pool containing a 90-degree corner room (`corner.tscn`), **When** the dungeon generator constructs the main path, **Then** it successfully aligns the corner room and subsequent rooms rotate to match the new heading.
2. **Given** a turn on the main path, **When** rooms are placed, **Then** their world AABBs are correctly rotated and checked for overlap against existing rooms to prevent intersection.

---

### User Story 2 - Curved Secondary Branches (Priority: P2)

As a dungeon designer, I want secondary branch paths to also support curves and turns, so that optional branching content can wind through the dungeon layout.

**Why this priority**: Extends winding paths to branches, allowing for complex and organic side-path structures.

**Independent Test**: Enable branches and include corner rooms in the branch/junction pools. Verify that the branch curves and backtracks or terminates correctly without colliding with the main path or other branches.

**Acceptance Scenarios**:

1. **Given** branch generation is enabled and the junction/corridor pools contain L-shaped or T-shaped rooms, **When** branches are generated, **Then** they curve according to the room connector configurations.
2. **Given** a branch path turns towards an existing room, **When** an AABB overlap is detected, **Then** the branch generator backtracks and resolves the conflict.

---

### User Story 3 - Diverse Angled Room Prefabs (Priority: P3)

As a level designer, I want a variety of pre-defined room scenes with connectors at different angles (like 90-degree turns and T-junctions) to showcase and test curved generation.

**Why this priority**: Necessary to provide test assets in the demo directory that actually enable curved generation for verification.

**Independent Test**: Use the new prefabs in the generator configuration and visually confirm that the dungeon layout utilizes corners and multi-door junctions successfully.

**Acceptance Scenarios**:

1. **Given** new scenes `corner.tscn` (90-degree corridor) and `t_junction.tscn` (3-door junction) placed in `demo/rooms/`, **When** the demo scene generates layouts, **Then** these rooms are successfully matched and instantiated.

---

### Edge Cases

- **Floating-point precision in rotation**: When aligning rooms at 90 or 270 degrees, floating-point inaccuracies in spatial coordinates or basis matrices could introduce tiny overlaps or micro-gaps. The system must tolerate slight float precision limits.
- **Self-collision on loopback**: A curved branch might loop back onto the main path or itself. The generator must detect the AABB collision and backtrack to find an alternative placement, preventing circular overlaps.
- **Connector match fail**: If a curved room's exit connector is pointing in a direction that cannot be resolved due to layout boundaries, the generator must backtrack.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `ConnectorMatcher` MUST compute correct alignment transforms for rooms where exit connectors are at non-opposing angles (e.g. 90, -90, 180, 270 degrees), strictly restricting turns to 90-degree increments.
- **FR-002**: The `DungeonBuilder` MUST correctly compute the world-space AABB of a room using its rotated `Transform3D` (swapping local X and Z size dimensions for 90/270 degree rotations to maintain tight axis-aligned bounds) before performing overlap checks.
- **FR-003**: The algorithm MUST support backtracking when a curved path results in a layout deadlock (AABB overlap).
- **FR-004**: Add `corner.tscn` to `demo/rooms/` containing a corridor script, custom room data resource, and two `RoomConnector3D` nodes oriented at a 90-degree angle.
- **FR-005**: Add `t_junction.tscn` to `demo/rooms/` containing a junction script, custom room data resource, and three `RoomConnector3D` nodes oriented at 90-degree angles to each other.
- **FR-006**: Ensure all math, coordinate systems, and transforms are processed in memory within pure GDScript classes (`ConnectorMatcher`, `DungeonBuilder`, `AABBManager`) before instantiating `Node3D` scenes, adhering to Core Logic Separation.
- **FR-007**: For rooms with multiple exit connectors (e.g., T-junctions or junctions), the `DungeonBuilder` MUST select one unused exit connector at random to continue the current path. The other exit connectors remain available as potential starting points for branch paths. Unused connectors at the end of generation receive blocker walls (`blocker.tscn`).
- **FR-008**: The selection between straight and curved rooms is purely driven by the designer-defined `spawn_weight` in the room configuration pools, without any hardcoded algorithmic preference.

### Key Entities

- **`RoomConnector3D`**: Represents a connection port in the room, containing its local transform relative to the room origin.
- **`ConnectorMatcher`**: Computes spatial alignments and matches connector types.
- **`DungeonBuilder`**: PROCEDURAL layout compiler.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of generated dungeons containing corner rooms align all connectors seamlessly with zero visual gaps or misplaced ports.
- **SC-002**: Zero interpenetration of room geometry in generated layouts (verified by AABB overlap checks in the test suite).
- **SC-003**: The builder successfully generates winding layouts with at least one 90-degree turn in under 1.0 second.

## Assumptions

- We assume standard connectors point along their local +Z or -Z axis, but the alignment code should genericize transform math to support arbitrary connector directions.
- All spatial math aligns with Godot 4's coordinate system (Right-Handed, Y-Up, -Z Forward).
- Vertical paths (multi-level generation) and layout loops/cycles (reconnecting paths) are out of scope. The dungeon layout remains flat (constant Y) and structured as a tree graph.
