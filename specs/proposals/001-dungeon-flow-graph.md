# Feature Proposal: Dungeon Flow Graph Editor

## 1. Overview & Goal
In Unity DunGen, dungeons are not configured via simple numeric parameters. Instead, they use a **Dungeon Flow** graph asset. This graph defines the sequential structure of the dungeon (e.g., Start Node -> Castle Area -> Transition Room -> Graveyard Area -> Boss Room) and allows designers to visually lay out branches, archetypes, and topological constraints.

The goal of this feature is to implement a visual, node-based **Dungeon Flow Graph Editor** in Godot using its built-in `GraphEdit` and `GraphNode` controls. This will allow level designers to visually define complex, multi-stage topologies instead of adjusting raw numbers in the Inspector.

---

## 2. Proposed Architecture & Godot Entities
To implement this in Godot, we will define the following data structures and editor controls:

### A. Data Models
1. **`DungeonFlowGraph` (Resource)**:
   - Serializes the graph representation.
   - Contains a list of node resources (`DungeonFlowNode`) and connection records.
2. **`DungeonFlowNode` (Resource)**:
   - Represents a node in the flow graph.
   - Properties:
     - `node_id`: Unique identifier.
     - `category`: The type of room pool (e.g., Entrance, Corridor, Junction, Boss, DeadEnd, or Custom Archetype).
     - `tile_set`: Refers to a `DungeonTileSet` resource (a subset of room pools).
     - `length_min` / `length_max`: If representing a sequence of rooms.
     - `graph_position`: Vector2 coordinate in the editor space.
3. **`DungeonFlowConnection` (Resource)**:
   - Connects two flow nodes.
   - Properties:
     - `from_node_id`: ID of the source node.
     - `to_node_id`: ID of the target node.
     - `is_locked`: Marks the connection as requiring a key (maps to the Lock & Key system).

### B. Editor Integration (Godot Plugin Control)
1. **`DungeonFlowEditor` (Control)**:
   - Extends Godot's `GraphEdit`.
   - Renders `DungeonFlowGraph` nodes using customized `GraphNode` controls.
   - Handles node dragging, creation, deletion, and connection routing.
2. **`DungeonFlowPlugin` (EditorPlugin)**:
   - Registers a bottom panel editor (similar to Godot's Shader or Animation editors) that opens whenever a `DungeonFlowGraph` resource is selected.

---

## 3. Usage Example & Configuration
A designer creates a `DungeonFlowGraph` resource, double-clicks it to open the editor panel, and creates:
1. An **Entrance Node** (selects Room Category: Entrance).
2. A **Sequence Node** (Castle TileSet, length 4-6).
3. A **Junction Node** branching into a **DeadEnd Node** (Graveyard TileSet, length 2).
4. A **Boss Node** linked to the end of the main path.

The `DungeonGenerator3D` inspector configuration changes to accept a single flow graph:
```gdscript
@export var flow_graph: DungeonFlowGraph
```

---

## 4. Implementation Steps
1. **Phase 1: Resources**: Implement the `DungeonFlowGraph`, `DungeonFlowNode`, and `DungeonFlowConnection` script resources.
2. **Phase 2: Flow Editor UI**: Design the bottom panel editor inside the plugin folder with `GraphEdit`, handling connecting/disconnecting slots.
3. **Phase 3: Generator Adaptation**: Update the `DungeonBuilder` algorithm. Instead of iterating linearly through a fixed spine length, it traverses the flow graph, selecting rooms from the configured node pools and following the node connection rules to construct the layout.
