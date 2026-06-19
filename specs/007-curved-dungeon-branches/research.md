# Research Notes: Curved Dungeon Branches

## 1. 3D Transform Alignment Mathematics (Godot 3D)

### Decision
We will reuse the generic transform alignment formula currently implemented in `ConnectorMatcher.compute_alignment_transform`.

### Rationale
To connect Room B to Room A at Connector A (world transform $T_{A, world}$) using Connector B (local transform $T_{B, local}$), Room B's world transform $T_{B, world}$ must satisfy the condition that Connector B's world transform matches Connector A's world transform rotated 180 degrees around the local Y-axis (facing opposite directions):
$$T_{B, world} \times T_{B, local} = T_{A, world} \times R_{Y}(180)$$
Multiplying by the inverse of $T_{B, local}$ on both sides yields:
$$T_{B, world} = (T_{A, world} \times R_{Y}(180)) \times (T_{B, local})^{-1}$$

This calculation is generic. Since it uses full matrices, it supports any connector orientation, including 90-degree curves (e.g. L-shaped rooms, T-junctions) natively without any code adjustments.

### Alternatives Considered
- **Grid-based coordinate translation**: Rejected because it limits room shapes to uniform grid sizes, whereas transform math supports arbitrary room bounding box sizes and orientations.

---

## 2. Bounding Box (AABB) Projections for Rotated Rooms

### Decision
To check collisions for rooms rotated at 90-degree increments, we transform the 8 local AABB corners by the room's world `Transform3D` and build an expanded axis-aligned bounding box around the transformed points.

### Rationale
For Y-axis rotations restricted to 90-degree increments (0, 90, 180, 270 degrees), the transformed local axes remain perfectly aligned with the world axes. Thus, transforming the corners and constructing an enclosing AABB results in a mathematically tight bounding box (effectively swapping local X and Z sizes for 90/270 degree rotations) with zero volume bloating. This keeps collision checks fast and allows reusing the core `AABB.intersects` and `AABBManager.check_overlap` logic without implementing complex OBB (Oriented Bounding Box) SAT (Separating Axis Theorem) code.

---

## 3. DFS Backtracking for Self-Collision and Deadlocks

### Decision
Ensure the procedural builder (`DungeonBuilder`) backtracks when a winding path curves back and collides with already placed rooms.

### Rationale
Unlike straight dungeons, curved paths can easily loop back on themselves. By enforcing recursive backtracking, if a branch path collides (spatial overlap check fails), the builder will:
1. Revert the last placed room.
2. Remove its world AABB from the placed array.
3. Try the next available room in the pool or backtrack further up the recursion stack.
This guarantees that layouts are solved successfully in memory without geometry overlap.
