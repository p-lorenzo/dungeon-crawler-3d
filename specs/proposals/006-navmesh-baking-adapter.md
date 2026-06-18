# Feature Proposal: NavMesh Baking Adapter

## 1. Overview & Goal
In DunGen for Unity, pathfinding is integrated by baking Unity NavMesh or A* Pathfinding Project data automatically after the dungeon is fully laid out. Since dungeons are generated dynamically at runtime or in the editor, static navmesh baking is impossible.

In Godot, pathfinding is handled by `NavigationRegion3D` using a NavigationMesh resource. Currently, our plugin instantiates the room geometry but does not bake navigation automatically, requiring designers to manually trigger bakes.
The goal of this feature is to implement a **Dungeon NavMesh Adapter** that detects room collisions/navigation geometry and automatically bakes the navigation mesh at runtime or editor-time immediately after dungeon generation completes.

---

## 2. Proposed Architecture & Godot Entities

### A. Core Adapter Node
1. **`DungeonNavMeshAdapter3D` (Node)**:
   - A component that designers attach to the `DungeonGenerator3D` or the scene tree.
   - Properties:
     - `navigation_region`: NodePath or reference to the target `NavigationRegion3D`.
     - `bake_on_completed`: Bool (default true) to auto-trigger baking when the generator finishes.
     - `use_collision_geometry`: Bool. If true, navigation parses physics collisions to bake navmesh instead of visual meshes.
     - `navigation_layers`: Bitmask determining pathfinding layers.

### B. Dynamic Baking Workflow
1. **Dungeon Generated Signal**:
   - `DungeonGenerator3D` completes instantiation and emits `generation_completed(dungeon_root)`.
2. **Adapter Interception**:
   - `DungeonNavMeshAdapter3D` receives the signal and retrieves the generated root.
3. **NavMesh Baking**:
   - The adapter checks if it's running in the editor or during gameplay.
   - It updates the `NavigationRegion3D` parsing source (setting it to read from the generated dungeon root container).
   - Triggers `navigation_region.bake_navigation_mesh(on_thread)` to compile the traversable mesh.

---

## 3. Usage Example & Configuration
1. The designer adds a `NavigationRegion3D` to the main scene.
2. They attach a `DungeonNavMeshAdapter3D` node as a child of the `DungeonGenerator3D`.
3. In the Inspector, the designer links the `NavigationRegion3D` to the adapter.
4. When they click "Generate" in the editor or trigger runtime generation:
   - The dungeon spawns.
   - The adapter automatically rebuilds the walk zones, allowing players and enemies to move instantly.

---

## 4. Implementation Steps
1. **Phase 1: Adapter Class**: Implement the `DungeonNavMeshAdapter3D` class extending Node.
2. **Phase 2: Signal Hookup**: Implement connection to `DungeonGenerator3D.generation_completed` signal.
3. **Phase 3: Dynamic Bake Scripting**: Write the logic using Godot's `NavigationServer3D` API to configure the bake settings dynamically and call `bake_navigation_mesh()`.
