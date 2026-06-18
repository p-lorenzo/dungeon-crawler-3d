# Feature Specification: Prop Randomizer & Clamping

**Feature Branch**: `004-prop-randomization`

**Created**: 2026-06-18

**Status**: COMPLETE

**Input**: User description: "specs/proposals/005-prop-randomization.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Designer Configures Prop Randomization (Priority: P1)

Dungeon designers can place `PropGroup3D` nodes in room scenes and configure the category, spawn chance, scene pool, and custom weights in the inspector.

**Why this priority**: This is the editor-facing design entry point for configuring random detail distributions in dungeons.

**Independent Test**: Add a `PropGroup3D` node to a test room scene and verify that the properties are export variables and editable.

**Acceptance Scenarios**:

1. **Given** a Room scene in the editor, **When** a designer adds a `PropGroup3D` node, **Then** they can view and configure `prop_category: String`, `spawn_chance: float`, `prop_pool: Array[PackedScene]`, and `weights: Array[float]` in the Inspector.
2. **Given** a selected `PropGroup3D` node, **When** the designer adds several scenes to the `prop_pool` and matching values to `weights`, **Then** the data is saved with the room scene.

---

### User Story 2 - Global Prop Clamping (Priority: P1)

The generator tracks category counts during room instantiation and enforces limits configured in the `DungeonConfig` resource to prevent too many instances of specific props (like rare chests or bosses).

**Why this priority**: Crucial for gameplay balancing, ensuring loot distribution and monster density are tightly controlled regardless of layout randomness.

**Independent Test**: Generate a dungeon layout with multiple chest prop nodes but a global limit of 2, and verify that no more than 2 chests spawn.

**Acceptance Scenarios**:

1. **Given** a global limit of 2 for category "chests" in `DungeonConfig`, **When** the dungeon generator instantiates 5 rooms that each contain a chest `PropGroup3D`, **Then** it spawns chests at only the first 2 processed groups and leaves the remaining 3 empty.
2. **Given** category limits in `DungeonConfig`, **When** the dungeon is generated, **Then** the `DungeonPropManager` keeps a running count and refuses to spawn props once limits are exceeded.

---

### User Story 3 - Weighted Pool Selection (Priority: P2)

The system selects which scene to instantiate from the pool by rolling against the relative weights provided, allowing rare vs. common props.

**Why this priority**: Enhances dungeon replayability and visual variety by introducing rarity levels for loot, decorations, and enemies.

**Independent Test**: Generate a high volume of a room containing a weighted prop pool and measure the spawn ratios to ensure they align with the defined weights.

**Acceptance Scenarios**:

1. **Given** a `PropGroup3D` with a pool of `[CommonChest, RareChest]` and weights `[9.0, 1.0]`, **When** the spawn chance check passes, **Then** the system instantiates `CommonChest` with a 90% probability and `RareChest` with a 10% probability.

---

### Edge Cases

- **Mismatched Array Lengths**: What happens when the length of `weights` does not match the length of `prop_pool`?
- **Floating Point Weights**: How are float weights handled when their sum does not equal exactly 1.0 or 100.0?
- **Zero spawn chance**: Setting `spawn_chance` to 0.0 must guarantee that no prop is instantiated.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a custom `PropGroup3D` node subclassing `Node3D` to represent candidate prop spawn locations.
- **FR-002**: The `PropGroup3D` class MUST export `prop_category: String`, `spawn_chance: float` (0.0 to 1.0), `prop_pool: Array[PackedScene]`, and `weights: Array[float]`.
- **FR-003**: The `DungeonConfig` resource subclass MUST support a `global_prop_limits: Dictionary` mapping category strings to integer maximum limits.
- **FR-004**: The `DungeonPropManager` RefCounted class MUST be initialized by `DungeonGenerator3D` during dungeon room instantiation to track category spawn counts.
- **FR-005**: The selection logic MUST normalize weight arrays automatically to handle arbitrary weight values.
- **FR-006**: The system MUST handle weights configuration mismatch by treating all items in the `prop_pool` as having equal weight (uniform random selection) and logging a warning in the editor.
- **FR-007**: The system MUST handle cleanup of unspawned prop groups by automatically calling `queue_free()` on the `PropGroup3D` node at runtime to remove it from the SceneTree, optimizing memory and rendering.
- **FR-008**: The system MUST support deterministic randomness for prop generation by sharing the dungeon generator's global random seed (passing the layout generator's `RandomNumberGenerator` instance reference to the prop selection logic).

### Key Entities *(include if feature involves data)*

- **PropGroup3D**: A custom spatial `@tool` node placed in room scenes representing placeholder locations for props.
  - Attributes: `prop_category: String`, `spawn_chance: float`, `prop_pool: Array[PackedScene]`, `weights: Array[float]`
- **DungeonPropManager**: A logic controller (`RefCounted`) initialized during instantiation that maintains counts and determines spawn eligibility.
- **DungeonConfig**: Upgraded configuration resource adding `global_prop_limits: Dictionary`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Under no circumstances may the total number of instantiated props in a category exceed the maximum limit defined in `DungeonConfig`.
- **SC-002**: Prop randomization and limit checking must execute in under 5ms for a dungeon with 100 `PropGroup3D` nodes, maintaining fast generation times.
- **SC-003**: Selection distribution ratios for a pool must fall within a 5% margin of error relative to the designer's defined weights after 1000 iterations.
- **SC-004**: Random selection must be deterministic; using the same seed on the same dungeon configuration must result in identical prop layout distribution.

## Assumptions

- Props are spawned statically during dungeon generation and do not move across rooms during the generation phase.
- Limiting rules apply globally across the entire dungeon layout.
- The player inventory or game state does not affect the generator's initial prop placement.
