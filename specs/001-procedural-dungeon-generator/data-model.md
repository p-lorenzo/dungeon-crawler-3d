# Data Model: Procedural Dungeon Generator

**Feature**: 001-procedural-dungeon-generator
**Date**: 2026-06-18

## Entity Overview

```
DungeonConfig (Resource)
  ├── topology parameters (int)
  ├── safety limits (int)
  └── 5× RoomData[] pools

RoomData (Resource)
  ├── PackedScene reference
  ├── probability weight (float)
  └── category (enum)

RoomConnector3D (Node3D, @tool)
  ├── connection_type (String)
  └── inherits Node3D transform

DungeonLayout (ref-counted, NOT a Resource/Node)
  ├── RoomPlacement[] (array of placed rooms)
  ├── ConnectorPair[] (array of connector edges)
  └── Path (start → boss node chain)
```

---

## DungeonConfig

**Extends**: `Resource`
**File**: `plugins/dungeon_crawler_3d/resources/dungeon_config.gd`
**Serialization**: `.tres`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `main_path_length` | `int` | 5 | Number of rooms along the entrance→boss spine |
| `branch_count` | `int` | 2 | Number of side branches to generate |
| `branch_depth_min` | `int` | 1 | Minimum rooms per branch (beyond junction) |
| `branch_depth_max` | `int` | 3 | Maximum rooms per branch (also safety limit) |
| `room_count_min` | `int` | 3 | Minimum total rooms in dungeon |
| `room_count_max` | `int` | 50 | Hard cap on total rooms (safety limit) |
| `random_seed` | `int` | 0 | Seed for RNG; 0 = random |
| `max_generation_attempts` | `int` | 10 | Retries per position before backtracking |
| `entrance_pool` | `Array[RoomData]` | `[]` | Rooms usable as dungeon entrance |
| `boss_pool` | `Array[RoomData]` | `[]` | Rooms usable as dungeon boss |
| `corridor_pool` | `Array[RoomData]` | `[]` | Rooms usable along paths |
| `junction_pool` | `Array[RoomData]` | `[]` | Rooms usable at branch points (optional hint) |
| `dead_end_pool` | `Array[RoomData]` | `[]` | Rooms usable at branch tips |

**Validation rules**:
- `main_path_length` >= 1
- `branch_count` >= 0
- `0 <= branch_depth_min <= branch_depth_max`
- `room_count_min <= room_count_max`
- `main_path_length + branch_count * branch_depth_min >= room_count_min` (satisfiable check, warning only)
- At least one pool must be non-empty
- `entrance_pool` and `boss_pool` must be non-empty for generation to succeed

**State**: Stateless — a pure data container. No lifecycle transitions.

---

## RoomData

**Extends**: `Resource`
**File**: `plugins/dungeon_crawler_3d/resources/room_data.gd`
**Serialization**: `.tres`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `room_scene` | `PackedScene` | `null` | Reference to the room's `.tscn` file |
| `spawn_weight` | `float` | 1.0 | Relative probability (≥ 0.0; 0.0 = disabled) |
| `category` | `int` (enum) | `CORRIDOR` | RoomCategory: ENTRANCE, BOSS, CORRIDOR, JUNCTION, DEAD_END |

**RoomCategory enum**:

| Value | Placement rule |
|-------|---------------|
| `ENTRANCE` (0) | Only at dungeon start (first room of main path) |
| `BOSS` (1) | Only at dungeon end (last room of main path) |
| `CORRIDOR` (2) | Any position along a path (main or branch) |
| `JUNCTION` (3) | Designer-preferred branch point; can also be placed as corridor. Any main-path room can spawn a branch, but junction rooms signal intent. |
| `DEAD_END` (4) | Only at branch tips; room must have exactly 1 connector |

**Validation rules**:
- `room_scene` must be a valid PackedScene reference (checked at generation time)
- `spawn_weight` >= 0.0
- If `spawn_weight == 0.0`, room is excluded from random selection
- `DEAD_END` rooms: the scene must contain at least 1 `RoomConnector3D` child

**State**: Stateless — pure data.

---

## RoomConnector3D

**Extends**: `Node3D` (or `Marker3D`)
**File**: `plugins/dungeon_crawler_3d/nodes/room_connector_3d.gd`
**Annotation**: `@tool`

| Property | Source | Type | Description |
|----------|--------|------|-------------|
| `position` | inherited (Node3D) | `Vector3` | Local position within the room scene |
| `rotation` | inherited (Node3D) | `Vector3` | Local rotation (Euler angles) |
| `connection_type` | `@export var` | `String` | Matching tag (e.g., `"standard_door"`, `"large_gate"`) |

**Validation rules**:
- `connection_type` must not be empty
- Matching: `connector_a.connection_type == connector_b.connection_type` (case-sensitive)

**State**: Stateless — a marker node. No lifecycle.

**Editor behavior** (`@tool`):
- Visible as a gizmo in the editor viewport (colored sphere + direction arrow)
- `connection_type` editable in the inspector
- When the parent room scene is saved, connectors are serialized with it

---

## DungeonLayout

**NOT a Resource or Node** — in-memory data structure built during generation, discarded after instantiation.

| Field | Type | Description |
|-------|------|-------------|
| `placements` | `Array[Dictionary]` | Ordered list of placed rooms before instantiation |
| `edges` | `Array[Dictionary]` | Connector pairings forming the dungeon graph |
| `main_path` | `Array[int]` | Indices into `placements` forming the start→boss spine |
| `branches` | `Array[Array]` | Array of branch node index chains |
| `total_rooms` | `int` | Total room count in the layout |

**RoomPlacement dictionary**:

| Key | Type | Description |
|-----|------|-------------|
| `room_data` | `RoomData` | Reference to the selected RoomData |
| `world_transform` | `Transform3D` | Computed world transform for instantiation |
| `category` | `int` | RoomCategory of the placed room |
| `parent_index` | `int` | Index of parent placement (-1 for entrance) |
| `connector_used` | `int` | Index of the connector on this room that was paired |

**ConnectorPair dictionary**:

| Key | Type | Description |
|-----|------|-------------|
| `room_a_index` | `int` | Index into placements |
| `room_b_index` | `int` | Index into placements |
| `connector_a_local` | `Transform3D` | Local transform of connector on room A |
| `connector_b_local` | `Transform3D` | Local transform of connector on room B |
| `connection_type` | `String` | The type tag shared by both connectors |

**Lifecycle**:
```
EMPTY → [build main path] → PARTIAL_SPINE
     → [attach branches]  → PARTIAL_BRANCHES
     → [validate path]     → VALID (ready for instantiation)
                           → INVALID (discard, signal failure)
```

---

## Entity Relationships

```
DungeonConfig ──contains──▶ RoomData[] (5 pools)
RoomData      ──references──▶ PackedScene
PackedScene   ──contains──▶ RoomConnector3D[] (child nodes)
DungeonLayout ──references──▶ RoomData (via RoomPlacement)
DungeonLayout ──contains──▶ RoomPlacement[]
DungeonLayout ──contains──▶ ConnectorPair[]
```
