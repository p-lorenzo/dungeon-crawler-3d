# Feature Proposal: Tile Injection System

## 1. Overview & Goal
In procedural generation, it is often necessary to guarantee that a specific room (such as a unique boss room, a merchant shop, or an interactive quest pedestal) appears exactly once in the layout and within a specific region (e.g. "somewhere in the middle of the dungeon", or "at the very end of a branch"). This is known as **Tile Injection**.

The goal of this feature is to implement a **Tile Injection System** in Godot that allows designers to define injection rules for unique rooms, including topological constraints (such as path depth percentages or branch-only rules) and strict enforcement.

---

## 2. Proposed Architecture & Godot Entities

### A. Data Models
1. **`TileInjectionRule` (Resource)**:
   - Properties:
     - `room_data`: The special `RoomData` to inject.
     - `min_path_percentage`: Float (0.0 to 1.0) indicating the minimum progress along the main path.
     - `max_path_percentage`: Float (0.0 to 1.0) indicating the maximum progress.
     - `placement_target`: Enum (`MAIN_PATH`, `BRANCH`, `ANYWHERE`).
     - `is_required`: Bool. If true, the dungeon generator will consider the generation a failure and retry (up to the maximum seed attempts) if it fails to place this room.

2. **`DungeonConfig` Upgrades**:
   - Add property `injected_tiles: Array[TileInjectionRule] = []`.

### B. Placement Algorithm Updates
We will modify the layout generator in `DungeonBuilder`:
1. During main path layout or branch layout:
   - The generator checks if any `TileInjectionRule` matches the current depth/percentage.
   - If a matching rule exists, the generator prioritizes placing the injected room over standard room pools.
2. After generation completes, a post-check validates that all `is_required` rules were satisfied. If any required rule failed to place, the generator discards the layout and retries with a new seed.

---

## 3. Usage Example & Configuration
A level designer wants to place a "Sacred Altar" room exactly in the middle of the dungeon.
They create a `TileInjectionRule`:
- `room_data`: `sacred_altar_data.tres`
- `min_path_percentage`: `0.4`
- `max_path_percentage`: `0.6`
- `placement_target`: `MAIN_PATH`
- `is_required`: `true`

When the generator builds the main path (e.g. length = 8), it reaches depth 4 (50% progress). The generator intercepts the rule, selects the Altar room, aligns it, and places it in the layout.

---

## 4. Implementation Steps
1. **Phase 1: Rule Resources**: Implement the `TileInjectionRule` resource script and link it in `DungeonConfig`.
2. **Phase 2: Builder Insertion Hook**: Update `DungeonBuilder` to scan active injection rules at each depth index of path/branch generation.
3. **Phase 3: Validation & Retries**: Add validation logic in `DungeonBuilder.build()` to ensure required injected tiles are present, and trigger retries if they are missing.
