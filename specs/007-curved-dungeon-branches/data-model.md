# Data Model: Curved Dungeon Branches

The curved branch generation utilizes standard Godot Resources and scene nodes to define topology and room characteristics.

## 1. RoomConnector3D (Scene Node)

Represents a connection port inside a room scene.

| Attribute | Type | Description |
|-----------|------|-------------|
| `connection_type` | `String` | Used to match compatible room openings (e.g. `"standard_door"`). |
| `transform` | `Transform3D` | Local transform defining the port's location and direction. Aligned such that local -Z is forward. |
| `is_locked` | `bool` | Lock status of this connector. |
| `key_id` | `String` | Associated key ID if locked. |

---

## 2. RoomData (Godot Resource)

Defines a room prefab configuration.

| Attribute | Type | Description |
|-----------|------|-------------|
| `room_scene` | `PackedScene` | Reference to the room scene (`.tscn`). |
| `category` | `RoomCategory` | Enum value (Entrance, Corridor, Junction, Boss, DeadEnd). |
| `spawn_weight` | `float` | Probability weight for random selection. |

---

## 3. DungeonConfig (Godot Resource)

The master parameters resource updated to control global limits and pools.

| Attribute | Type | Description |
|-----------|------|-------------|
| `main_path_length` | `int` | Length of critical path (minimum 1). |
| `branch_count` | `int` | Number of side branches. |
| `room_count_min` | `int` | Total room count minimum. |
| `room_count_max` | `int` | Total room count maximum (hard cap). |
| `injected_tiles` | `Array[TileInjectionRule]` | Array of rules for injecting unique rooms. |

---

## 4. DungeonGraph (In-Memory Data)

Models the generated layout graph.

### Placement Dictionary Schema

Each node in `placements` contains:
- `room_data`: `RoomData`
- `world_transform`: `Transform3D` (describes aligned position and Y-rotation)
- `category`: `RoomCategory`
- `parent_index`: `int` (index of predecessor room in placements array)
- `connector_used`: `int` (index of connector matched in this room)

### Edge Dictionary Schema

Each connection in `edges` contains:
- `room_a_index`: `int`
- `room_b_index`: `int`
- `connector_a_local`: `Transform3D` (transform of connector in Room A space)
- `connector_b_local`: `Transform3D` (transform of connector in Room B space)
- `connection_type`: `String`
