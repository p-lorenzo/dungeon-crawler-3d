# Feature Proposal: Lock & Key Puzzle System

## 1. Overview & Goal
In larger dungeons, players often need keys to progress through locked doors. This is handled dynamically during post-processing: the generator identifies designated "locked" connections between rooms, assigns a lock, and then distributes key items in preceding room tiles. Crucially, the generator guarantees that the key is placed in a room reachable *before* the player encounters the corresponding locked door, avoiding soft-locks.

The goal of this feature is to implement an automated **Lock & Key Puzzle System** in the Godot Dungeon Generator that places keys in reachable containers/chests and locks on doorways according to the topological layout.

---

## 2. Proposed Architecture & Godot Entities
To build this in Godot, we will define the following resources and nodes:

### A. Key-Lock Components (For Room Scenes)
1. **`KeySpawnPoint3D` (Node3D)**:
   - A placeholder node placed inside room scenes where a key can potentially spawn (e.g. inside a chest, on a pedestal, or dropped by an enemy).
   - Exposes a key group identifier.
2. **`RoomConnector3D` Upgrades**:
   - Add property `lock_type: String` (e.g. "none", "red_key", "boss_key").
   - During generation, if a connection is locked, the generator flags the instantiated doorway to spawn a locked door mesh/actor instead of a normal open archway.

### B. Logic & Post-Processor
1. **`KeyLockManager` (RefCounted class)**:
   - Executed as a post-generation phase in `DungeonBuilder`.
   - Iterates through the generated `DungeonGraph` and identifies all locked connections.
   - For each lock:
     - Traces the graph backward from the locked doorway to the dungeon entrance (finding all valid predecessor rooms).
     - Gathers all active `KeySpawnPoint3D` nodes in those predecessor rooms.
     - Selects one spawn point randomly (weighted if requested) and assigns the key item to spawn there.
     - Registers the key-door pairing.

---

## 3. Usage Example & Configuration
1. The designer adds a `RoomConnector3D` to their transition room scene and checks `Is Locked = true` with `Key ID = "castle_key"`.
2. Inside their castle corridor scenes, the designer places chest prefabs containing a `KeySpawnPoint3D` node.
3. During generation, the `KeyLockManager` runs, verifies that a key with ID `"castle_key"` must be placed, traces the rooms back to the entrance, selects one of the chests in those rooms, and spawns the key inside it.
4. When the dungeon is instantiated:
   - The transition doorway instantiates a locked gate.
   - The chosen chest instantiates the key item.

---

## 4. Implementation Steps
1. **Phase 1: Component Nodes**: Create the `KeySpawnPoint3D` node script and update `RoomConnector3D` to support lock configurations.
2. **Phase 2: Predecessor Graph Traversal**: Implement backtracking/traversal methods in `DungeonGraph` to find all ancestor rooms given a node index.
3. **Phase 3: Key Allocation**: Implement the `KeyLockManager` class that maps keys to available spawn points in ancestor rooms.
4. **Phase 4: Spawning Integration**: Update `DungeonGenerator3D._instantiate_rooms()` to dynamically spawn key items and swap door meshes based on the post-processed lock data.
