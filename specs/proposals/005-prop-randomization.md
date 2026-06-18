# Feature Proposal: Prop Randomizer & Clamping

## 1. Overview & Goal
In procedurally generated levels, visual and gameplay variety within individual rooms is key. In Unity DunGen, this is handled via **Prop Randomization** and the **Global Prop Component**.
- **Prop Randomization**: Places place-holders in room tiles that select a random object to spawn from a weighted pool.
- **Global Prop Component**: Restricts the maximum number of times a certain prop (like a treasure chest or health pickup) can spawn across the entire dungeon layout, preventing the level from being overloaded with loot.

The goal of this feature is to implement a **Prop Randomization and Clamping System** in Godot that randomizes details within room tiles post-generation while respecting global limits.

---

## 2. Proposed Architecture & Godot Entities

### A. Component Node (For Room Scenes)
1. **`PropGroup3D` (Node3D)**:
   - A placeholder node placed in room scenes where props should be randomized.
   - Properties:
     - `prop_category`: String key (e.g. "chests", "monsters", "barrels").
     - `spawn_chance`: Float (0.0 to 1.0) defining the likelihood of spawning anything.
     - `prop_pool`: Array of `PackedScene` representing potential props.
     - `weights`: Array of floats corresponding to spawn weights for each scene in the pool.

### B. Configuration & Manager
1. **`DungeonConfig` Upgrades**:
   - Add property `global_prop_limits: Dictionary` (mapping category keys to integer max limits, e.g. `{"chests": 5, "monsters": 20}`).
2. **`DungeonPropManager` (RefCounted class)**:
   - Tracks spawn counts per category.
   - Evaluated during room instantiation.
   - Methods:
     - `should_spawn(category: String) -> bool`: Checks if category has reached its limit.
     - `increment_count(category: String)`: Increments count.

---

## 3. Usage Example & Configuration
A designer creates a "Graveyard Room" scene:
- They place a `PropGroup3D` node in the center of the room.
- Set `prop_category` to `"chests"`.
- Set `prop_pool` to `[common_chest.tscn, gold_chest.tscn]`.
- Set `weights` to `[0.8, 0.2]`.

In the `DungeonConfig` resource, the designer defines a limit:
- `"chests" -> 4`

When the generator instantiates the dungeon:
- The first 4 times a `PropGroup3D` with category `"chests"` is processed, it rolls its spawn chance and instantiates a common or gold chest.
- Any subsequent `PropGroup3D` nodes of category `"chests"` will automatically destroy themselves or remain empty, guaranteeing that no more than 4 chests exist in the entire level.

---

## 4. Implementation Steps
1. **Phase 1: Prop Component**: Build the `PropGroup3D` class with editor visual aids.
2. **Phase 2: Global Manager**: Build the `DungeonPropManager` to track category limits.
3. **Phase 3: Integration Hook**: Update `DungeonGenerator3D._instantiate_rooms()` to initialize the prop manager and query it when traversing `PropGroup3D` nodes in instantiated rooms.
