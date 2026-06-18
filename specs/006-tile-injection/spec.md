# Feature Specification: Tile Injection System

**Feature Branch**: `006-tile-injection`

**Created**: 2026-06-18

**Status**: COMPLETE

**Input**: User description: "Inject unique rooms (like a boss room, merchant shop, or quest pedestal) exactly once in the layout within a specific path depth percentage range."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Inject unique room on main path (Priority: P1)

As a dungeon designer, I want to define a rule to place a specific unique room (e.g. a mini-boss room or puzzle room) exactly once along the main path within a percentage range of its length, so that the player encounters it at a paced moment (e.g., halfway through the level).

**Why this priority**: Core value of the Tile Injection System. Without this, the generator has no way to place unique rooms deterministically along the main path.

**Independent Test**: Configure a main path of 8 rooms, add an injection rule for room X with a percentage range of 0.4 to 0.6. Generate a dungeon, and check that room X is present in the layout at depth 3, 4, or 5.

**Acceptance Scenarios**:

1. **Given** a dungeon configuration with `main_path_length = 10` and one `TileInjectionRule` for `merchant_shop` with `min_path_percentage = 0.3` and `max_path_percentage = 0.5`, **When** the dungeon is generated successfully, **Then** the merchant shop room is placed exactly once, and its index on the main path is between 3 and 5 inclusive.
2. **Given** multiple matching main-path injection rules at different depth ranges, **When** the dungeon is generated, **Then** they are all placed in their respective depth zones without overlaps or duplicates.

---

### User Story 2 - Required injection failure and retry (Priority: P2)

As a designer, I want to mark an injection rule as required so that if the generator fails to place this room (e.g., because of spatial overlap or incompatible connectors), the system retries with a new seed, ensuring the playable level always has all required unique rooms.

**Why this priority**: Essential for game flow. If a critical room (like a quest item room) is omitted, the dungeon is incomplete.

**Independent Test**: Add a required injection rule for a room with an incompatible connector type (e.g., connector type "X" which is not present in the dungeon entrance or corridors). Trigger generation. Verify it fails cleanly and emits `generation_failed` after retrying.

**Acceptance Scenarios**:

1. **Given** a required injection rule that cannot be satisfied due to connector mismatch, **When** generation is triggered, **Then** the builder retries up to `max_generation_attempts` and then fails, emitting the `generation_failed` signal.
2. **Given** a required injection rule that initially fails due to spatial overlap but succeeds on a subsequent seed, **When** generation is run, **Then** the dungeon is successfully built and contains the required room.

---

### User Story 3 - Inject on branch (Priority: P3)

As a designer, I want to inject a unique room on a side branch rather than the main path, so that optional content (like secret chests or NPC encounters) is correctly placed away from the critical path.

**Why this priority**: Adds richness to layouts by supporting optional branching content.

**Independent Test**: Create a rule with target `BRANCH` and depth range `0.5` to `1.0`. Verify the room spawns on one of the side branches and not on the main path.

**Acceptance Scenarios**:

1. **Given** an injection rule targeting `BRANCH` at range `0.5` to `1.0`, **When** the dungeon has side branches and is generated, **Then** the injected room is placed at the outer half of one of the branches.

---

### Edge Cases

- **Multiple rules matching the same index**: If multiple injection rules match the same slot/index, the system should sort them (e.g., by priority or ID) and try to place them sequentially or in a deterministic order.
- **Incompatible connectors on injected room**: If the injected room has connectors that do not match the predecessor room, the layout step fails. The builder backtracks or retries with a new seed.
- **Zero path length**: If main path length is 1, a rule with range `0.5` to `1.0` cannot be satisfied. The system should gracefully handle division-by-zero or round to appropriate indexes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Implement `TileInjectionRule` as a Godot `Resource` subclass. It MUST export:
  - `room_data: RoomData` (the custom room scene configuration)
  - `min_path_percentage: float` (0.0 to 1.0)
  - `max_path_percentage: float` (0.0 to 1.0)
  - `placement_target: int` (enum: `MAIN_PATH` = 0, `BRANCH` = 1, `ANYWHERE` = 2)
  - `is_required: bool` (if true, failure to place this room triggers a retry or overall failure)
- **FR-002**: Upgrade `DungeonConfig` to export `injected_tiles: Array[TileInjectionRule] = []`.
- **FR-003**: `DungeonBuilder` MUST scan `injected_tiles` during path and branch generation. When about to place a room at depth `d` of a path/branch of total expected length `L`:
  - Calculate percentage `p = d / (L - 1)` (or `0.0` if `L <= 1`).
  - Find all rules matching the current percentage and target (e.g. `MAIN_PATH` or `BRANCH`).
  - If a matching rule is found, prioritize placing the injected room over standard room pools.
- **FR-004**: If an injected room is placed, it MUST be removed from the pool of active rules for that generation run to ensure it is placed exactly once (unless configured otherwise, but by default once).
- **FR-005**: After layout planning (in-memory) is done, `DungeonBuilder` MUST verify that all `is_required` rules have been successfully placed. If any required rule is missing, the layout planning is marked as a failure.
- **FR-006**: On planning failure, the generator MUST retry with a new seed, up to `max_generation_attempts`. If all attempts fail, it MUST emit `generation_failed` with a clear reason.

### Key Entities

- **`TileInjectionRule`**: Represents an injection configuration for a unique room, detailing where and when it can appear.
- **`DungeonConfig`**: The resource containing global generation parameters, updated to store the list of active injection rules.
- **`DungeonBuilder`**: The core layout planning engine, updated to evaluate injection rules at each depth.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of successful dungeon generations contain all `is_required` injected rooms.
- **SC-002**: Injected rooms are placed strictly within their configured percentage range along the path they target.
- **SC-003**: Generating a dungeon with unsolvable required injection rules terminates cleanly (within 2.0 seconds for max 10 attempts) and emits the `generation_failed` signal.

## Assumptions

- Each `TileInjectionRule` defines a single room instance to be injected.
- Acronyms and enum values are strictly statically typed.
- Pre-existing features (Lock & Key, Doorway Blockers, Props) are fully compatible and run after room injection layout planning is resolved.
