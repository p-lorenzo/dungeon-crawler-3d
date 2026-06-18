# Feature Proposal: Doorway Blocker & Prefab Adapters

## 1. Overview & Goal
In Unity DunGen, a **Doorway** is a component that acts as a connector between room tiles. It handles visual matching dynamically:
- If a connection is **active** (connects to another tile), DunGen spawns a door frame or open gateway.
- If a connection is **unused** (leads to a dead-end void), DunGen spawns a "Blocker" (e.g. a solid wall, heap of rubble, or closed gate) to seal the level so the player doesn't fall into the void.

Currently in our Godot implementation, unused room connectors are left open, creating gaping holes in the dungeon walls.
The goal of this feature is to upgrade `RoomConnector3D` to automatically instantiate **active doors** or **blocker walls** depending on whether they are connected in the final layout.

---

## 2. Proposed Architecture & Godot Entities

### A. Upgraded `RoomConnector3D`
We will add scene template exports to `RoomConnector3D` to specify the assets spawned:
```gdscript
@tool
class_name RoomConnector3D
extends Node3D

@export var connector_type: String = "standard"

# Asset spawned when this doorway connects to another room
@export var doorway_scene: PackedScene

# Asset spawned when this doorway is unused (leads to empty space)
@export var blocker_scene: PackedScene
```

### B. Procedural Spawning Logic
During dungeon instantiation (`DungeonGenerator3D._instantiate_rooms()`), we will iterate over each room node's connectors:
1. Retrieve all children of type `RoomConnector3D`.
2. For each connector, check if it matches an edge in `DungeonGraph`.
3. If an edge exists matching this connector's position and type:
   - Instantiate `doorway_scene` as a child of the connector (aligned to its transform).
4. If no edge exists (the connector is unused):
   - Instantiate `blocker_scene` as a child of the connector to seal the opening.

---

## 3. Usage Example & Configuration
A designer builds a "Castle Corridor" room scene:
- They place a `RoomConnector3D` at the north doorway.
- They configure `doorway_scene` with `castle_archway.tscn` (an open arch).
- They configure `blocker_scene` with `castle_wall.tscn` (a solid stone wall).

If the corridor is connected to another room to the north, the archway spawns, allowing the player to pass. If the generator decides to branch elsewhere and leave the north connector open, a solid stone wall automatically spawns, closing the gap.

---

## 4. Implementation Steps
1. **Phase 1: Script Upgrades**: Add `doorway_scene` and `blocker_scene` exports to `RoomConnector3D`.
2. **Phase 2: Edge Mapping**: Implement a helper method in `DungeonGraph` to quickly query if a specific room connector (by index or local transform) is mapped to an edge.
3. **Phase 3: Instantiation Assembly**: Modify `DungeonGenerator3D._instantiate_rooms()` to scan instantiated rooms for `RoomConnector3D` nodes and spawn the appropriate sub-scenes (doorway vs. blocker).
