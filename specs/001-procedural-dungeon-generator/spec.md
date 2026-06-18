# Feature Specification: Procedural Dungeon Generator

**Feature Branch**: `001-procedural-dungeon-generator`

**Created**: 2026-06-18

**Status**: Draft

**Input**: User description: "costruiamo un plugin godot che permetta di generare dei dungeon procedurali a partire da una configurazione del dungeon (numero di rami, profonditá rami, lunghezza percorso principale etc.) e da varie stanze 'prefab/packedscene' create con dei connettori che permettono di connettersi ad altre stanze, il più quanto simile ma migliore e più semplice del plugin dungen giá esistente su unity"

## Clarifications

### Session 2026-06-18

- Q: Where does the plugin reside relative to the testbed project? → A: The repository root is a committed Godot testbed project; the actual plugin lives under the `plugins/` directory.
- Q: Should rooms have formal categories for placement logic? → A: Complete categories (5): entrance, boss, corridor, junction, dead-end — each with automatic placement rules.
- Q: Can branches attach to any main-path room or only junctions? → A: Any main-path room can spawn a branch (max 1 per room). Junctions are optional designer hints for preferred branch points.
- Q: Must connectors have exactly opposite orientations to match? → A: Free alignment — the system calculates the rotation needed to align any pair of same-type connectors regardless of their original orientation.
- Q: One global room pool or per-category pools? → A: Per-category pools: DungeonConfig has 5 separate lists (entrance, boss, corridor, junction, dead-end). Each room goes in its category's pool only.
- Q: Fixed branch depth or min-max range? → A: Min-max range: DungeonConfig has `branch_depth_min` and `branch_depth_max`. Each branch gets a random depth within the range.
- Q: How does the generator pick among multiple valid room candidates? → A: Weighted random selection with cooldown — recently placed rooms get a temporary penalty to reduce consecutive repeats.
- Q: What happens when no valid room candidate fits a placement slot? → A: Local backtracking (1 step): undo the last placed room, pick an alternative candidate, and retry. Repeat up to max_generation_attempts per step before failing.
- Q: Should DungeonConfig define connector type compatibility rules? → A: Exact string match only. Two connectors match if and only if their type tags are identical. No compatibility matrix needed.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Generate a Dungeon from Room Pool (Priority: P1)

A level designer has a collection of pre-built room scenes, each tagged with connector points. They assign these rooms to a dungeon generator node, press a button in the editor, and the system produces a connected, non-overlapping dungeon layout with a valid path from entrance to exit.

**Why this priority**: This is the core value proposition — without the ability to generate a basic dungeon, nothing else matters. It validates the entire connector-matching and spatial-placement pipeline.

**Independent Test**: Create three room scenes (entrance, corridor, exit) with matching connectors, add them to the generator's room pool, and click "Generate". Verify the output contains all three rooms, they do not overlap, and a traversable path connects entrance to exit.

**Acceptance Scenarios**:

1. **Given** a dungeon generator configured with a pool of 5 compatible room scenes, **When** the designer triggers generation, **Then** the system produces a dungeon with at least 3 rooms, no geometry overlaps, and a valid path from the designated start room to the designated exit room.
2. **Given** a dungeon generator with rooms that have incompatible connector types (e.g., "large door" vs "small door"), **When** generation is triggered, **Then** the system only connects rooms whose connector types match, and reports any unused connectors.
3. **Given** a dungeon generator with no exit room reachable from the start, **When** generation exhausts all placement attempts, **Then** the system signals a generation failure with a descriptive error rather than producing an incomplete dungeon.

---

### User Story 2 - Configure Dungeon Topology (Priority: P2)

A level designer wants control over the dungeon's structure: how many side branches exist, how deep each branch goes, and how long the main path from entrance to boss should be. They adjust numeric parameters in the inspector and the generated dungeon respects these topological constraints.

**Why this priority**: Topology control differentiates this tool from naive random generation. It gives designers artistic direction while keeping the process automated. This is the feature the user explicitly highlighted ("numero di rami, profonditá rami, lunghezza percorso principale").

**Independent Test**: Configure a generator with main path length = 5, branches = 2, branch depth min = 1, branch depth max = 3. Generate 10 dungeons and verify that in each: the main path has exactly 5 rooms, there are exactly 2 branches, and every branch depth falls within [1, 3]. Use a fixed seed for reproducibility.

**Acceptance Scenarios**:

1. **Given** dungeon config with main path length set to 4, **When** generation completes, **Then** exactly 4 rooms form a linear sequence from entrance to exit (the "spine"), regardless of branches.
2. **Given** dungeon config with 3 branches, branch depth min = 2, branch depth max = 2, **When** generation completes, **Then** 3 side chains emanate from rooms on the main path, each containing exactly 2 additional rooms beyond the junction.
3. **Given** dungeon config with zero branches, **When** generation completes, **Then** the dungeon consists solely of the main path with no side rooms.

---

### User Story 3 - Iterate in the Editor Without Running the Game (Priority: P3)

A level designer wants to tweak room probabilities, connector types, and topology parameters, then instantly see the result in the Godot editor viewport — without ever pressing "Play". They generate, inspect, adjust, and regenerate in rapid cycles.

**Why this priority**: Editor-only iteration dramatically accelerates level design workflows. It is a key differentiator versus Unity's DunGen which often requires entering play mode.

**Independent Test**: Open the demo scene in the Godot editor. Change a topology parameter in the inspector. Click "Generate". Verify the 3D viewport updates with the new dungeon layout immediately, without the game running. Repeat 5 times with different parameters.

**Acceptance Scenarios**:

1. **Given** the Godot editor is open with a dungeon generator node selected, **When** the designer modifies the "main path length" parameter from 4 to 6 and clicks "Generate", **Then** the viewport shows a new dungeon with a 6-room main path within 2 seconds, without entering play mode.
2. **Given** a generated dungeon is visible in the editor viewport, **When** the designer clicks "Clear", **Then** all generated room instances are removed from the scene tree, leaving only the generator node.
3. **Given** a dungeon generation completes successfully, **When** the completion signal fires, **Then** downstream editor tools (e.g., NavMesh baker) can react to the new geometry without manual intervention.

---

### Edge Cases

- What happens when the room pool is empty? The generator must report a clear error and not crash.
- What happens when no two rooms have matching connector types? The generator must exhaust attempts and signal failure with a descriptive reason.
- What happens when the requested main path length exceeds the available rooms in the pool? The generator must report that constraints cannot be satisfied.
- What happens when spatial constraints (overlap avoidance) prevent placing enough rooms to satisfy branch counts? The generator must place as many as possible and signal a partial-success or fallback.
- What happens when a room PackedScene is missing or its file path is broken? The generator must detect missing resources before generation and report the specific broken reference.
- What happens when a room has zero connectors defined? The room is treated as a dead-end and can only be placed at branch tips.
- What happens with extremely large parameter values (e.g., 1000 rooms)? The generator must enforce a configurable upper limit to prevent editor freeze.
- What happens when the requested number of branches exceeds the number of rooms available on the main path? The generator must spawn as many branches as possible (one per main-path room) and report how many were placed vs. requested.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST produce a dungeon layout consisting of rooms connected via matching connector points, with no two rooms overlapping in 3D space.
- **FR-002**: The system MUST guarantee a traversable path exists from a designated start room to a designated end room in every successfully generated dungeon.
- **FR-003**: Designers MUST be able to configure the number of side branches, the minimum and maximum depth of each branch, and the length of the main path as numeric parameters.
- **FR-004**: The system MUST allow designers to assign rooms to five per-category pools (entrance, boss, corridor, junction, dead-end) in DungeonConfig. Each room entry has configurable spawn probability weight. The generator selects rooms from the pool matching the required category for the placement slot.
- **FR-005**: Each room scene MUST expose connector points that specify position, orientation, and a connection type tag (e.g., "standard_door", "large_gate"). Two connectors match if and only if their type tags are exactly identical (case-sensitive string equality). The system MUST automatically compute the transform (translation + rotation) to align any two matching connectors regardless of their original orientation.
- **FR-006**: The system MUST operate entirely within the Godot editor via `@tool` script execution, without requiring the game to run.
- **FR-007**: The generator MUST provide "Generate" and "Clear" actions triggerable from the editor inspector.
- **FR-008**: The system MUST emit a signal upon successful generation completion to allow downstream tools to react.
- **FR-009**: The system MUST emit a signal upon generation failure, including a human-readable reason for the failure.
- **FR-010**: All generation parameters (topology, room pool, connector matching rules, seed) MUST be serializable as a single configuration asset that can be saved, versioned, and shared.
- **FR-011**: The system MUST support a random seed parameter to enable reproducible dungeon generation.
- **FR-012**: The system MUST enforce a configurable upper limit on total room count, per-position backtracking attempts (`max_generation_attempts`), and branch depth to prevent infinite loops or editor freezes. The branch depth max parameter doubles as the branch depth safety limit.
- **FR-013**: The generator MUST use weighted random selection with a cooldown mechanism: a room that was recently placed receives a temporary probability penalty to reduce consecutive repetitions, ensuring visual variety across the dungeon.
- **FR-014**: When no valid room candidate fits a placement slot, the generator MUST perform local backtracking: undo the last placed room, select an alternative candidate for that position, and retry forward placement. This retry cycle repeats up to `max_generation_attempts` per position before reporting generation failure.

### Key Entities

- **DungeonConfig**: A serializable configuration asset holding all generation parameters — main path length, branch count, branch depth min/max, room count min/max, random seed, max generation attempts, and five per-category room pools (entrance, boss, corridor, junction, dead-end).
- **RoomData**: A serializable entry in the room pool referencing a PackedScene, its spawn probability weight, and a mandatory room category (entrance, boss, corridor, junction, dead-end). Placement rules: entrance only at start; boss only at end; corridor along any path position; junction marks a designer-preferred branch point but any main-path room can spawn a branch (max 1 per room); dead-end only at branch tips with no outgoing connections.
- **RoomConnector**: A point defined within a room scene specifying a local transform (position + rotation) and a connection type tag (case-sensitive string). Two connectors match if and only if their type tags are identical. The system computes the world transform to align them so they occupy the same position facing opposite directions.
- **DungeonLayout**: The in-memory result of generation before instantiation — a graph of placed rooms with their world transforms, connector pairings, and the validated path from start to end.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A designer with 5 pre-built room scenes can generate a valid dungeon within 3 seconds of clicking "Generate" on commodity hardware.
- **SC-002**: 100% of successful generations produce dungeons with a traversable path from entrance to exit (verified by automated path walk).
- **SC-003**: A designer can complete a full iteration cycle (adjust parameter → generate → inspect → clear) in under 10 seconds without leaving the editor.
- **SC-004**: The system handles a pool of 50 room scenes and a target of 30 rooms without exceeding 5 seconds of generation time.
- **SC-005**: The plugin functions correctly as a reusable addon — a fresh Godot project can install it by copying the `plugins/` directory and enabling the plugin, with no additional setup steps.

## Assumptions

- Target users are Godot game developers and level designers familiar with the Godot editor and inspector workflow.
- Room scenes are manually authored by the designer with connector nodes placed in advance; the plugin does not auto-generate room geometry.
- Rooms are axis-aligned for AABB overlap detection; arbitrary rotation of rooms is limited to 90-degree increments around the Y-axis (vertical).
- The plugin targets single-floor dungeons in v1; multi-floor/vertical stacking is out of scope.
- All rooms are roughly similar in scale; the system does not auto-scale rooms to fit connectors.
- The demo scene serves as both development test harness and user-facing example.
- The repository root is a Godot testbed project (committed). The plugin source code lives under the `plugins/` directory, separate from the testbed. The testbed consumes the plugin as a local addon for development and testing.
