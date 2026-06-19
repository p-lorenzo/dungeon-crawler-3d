# Class Contract: DungeonBuilder

 процедура procedurally compiles dungeon layouts in memory.

## Public Interface

### `build`
```gdscript
func build(config: DungeonConfig) -> DungeonGraph
```
Takes a `DungeonConfig` resource and generates a layout graph `DungeonGraph`. Returns an empty layout graph if generation fails completely.

### Public Fields

- `failure_reason: String`: Captures the error reason if layout planning fails.
- `partial_success_note: String`: Captures warnings (e.g. fewer branches placed than requested due to spatial constraints).
- `branches_placed: int`: Number of side branches successfully placed.
- `branches_requested: int`: Number of side branches requested.

## Spatial Algorithms & Constraints

### 90-Degree AABB Expansion
When verifying collision of a room candidate placed at `world_transform`, its axis-aligned bounds must be transformed:
1. Extract the local AABB of the room mesh geometries (`_compute_scene_aabb`).
2. Multiply all 8 local AABB corners by the `world_transform`.
3. Construct a new world AABB by expanding around these rotated points. For 90-degree increments, this constructs a tight AABB without padding.
4. Pass the world AABB to `AABBManager.check_overlap` to detect overlap against all placed room AABBs.

### DFS Backtracking
The builder recurses along `_place_path_node_recursive` and `_place_branch_node_recursive`. If a placement overlaps:
1. Reject the candidate.
2. If all candidates in the pool fail, return `false` to backtrack to the predecessor node.
3. Upon backtrack, remove the last placement, its edge, and its AABB bounds.
