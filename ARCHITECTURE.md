# Godot Plugin Specification: Dungeon Crawler 3D

## 1. Project Overview

**Dungeon Crawler 3D** is a Godot Engine plugin focused on procedural 3D dungeon generation. Inspired by tools like "DunGen" (Unity), the system dynamically assembles complex levels from predefined rooms (modules saved as `PackedScene`), joining them through compatible "connectors" or "doors".

The goal is to provide a robust, high-performance tool natively integrated into the Godot editor, automating level design while maintaining strict control over path flow and validity.

## 2. System Architecture

The plugin enforces a clear separation of responsibilities between data computation and engine instantiation.

### 2.1. Core Logic (The Generation Engine)

All placement logic operates in memory before interacting with the `SceneTree`.

- **Graph/Grid Management:** The algorithm evaluates the floor plan as a mathematical graph or spatial grid.
- **Logical Collision Detection:** Computation prevents spatial interpenetration of rooms (AABB bounding box overlap test) *before* instantiating 3D nodes.
- **Path Validation:** Ensures a valid path always exists between the `Start` node and the `Boss/Exit` node.

### 2.2. Godot Representation and Integration

- **DungeonGenerator (Custom Node):** A custom node (`Node3D`) exposed in the Godot editor that acts as the entry point and configuration manager.
- **Room Connector (Custom Node):** A node (`Marker3D` or similar) to be placed inside room `PackedScene` files to define coordinates, rotation, and door metadata (e.g., "Small Door", "Main Door").

## 3. File System Structure

The plugin must reside entirely within `plugins/dungeon_crawler_3d/`.

    dungeon-crawler-3d/
    ├── plugins/
    │   └── dungeon_crawler_3d/
    │       ├── plugin.cfg                  # Godot plugin metadata
    │       ├── dungeon_crawler_3d.gd       # EditorPlugin script (setup and teardown)
    │       ├── core/                       # Decoupled core logic (algorithms, graphs, validation)
    │       ├── nodes/                      # Custom nodes exported in the editor (Generator, Connector)
    │       └── resources/                  # Custom Resources (e.g., DungeonSettings, RoomData)
    ├── demo/                               # Test scenes and assets for development (outside the plugin)
    └── project.godot

## 4. AI Agent Specifications (Speckit / OpenCode)

The initial code generation goal is to define the architectural foundations. Agents are expected to proceed through the following sequential steps:

1.  **Data Definition (Custom Resources):**
    - Write a `RoomData` class (extends `Resource`) that stores references to `PackedScene` files and their spawn probabilities or constraints.
    - Write a `DungeonConfig` class (extends `Resource`) for generation parameters (e.g., min/max room count, random seed, max generation attempts).
2.  **Node Definition (Custom Nodes):**
    - Create the script for `RoomConnector3D` (extends `Node3D` or `Marker3D`). It must expose variables for connection type and calculate a ray (logical RayCast) to determine the adjacent room's orientation.
    - Create the script for `DungeonGenerator3D` (extends `Node3D`), which will expose editor buttons (using `@tool` in GDScript) to trigger generation directly in the editor.
3.  **Base Algorithm (Core Builder):**
    - Develop an abstract builder in `core/` that accepts a configuration, chooses an initial room, identifies open `RoomConnector3D` nodes, randomly selects a compatible room from the pool, and applies the spatial transformation (rotation/translation) to align the connectors.

## 5. Strict Technical Requirements

- **Language:** GDScript.
- **Extensive use of the `@tool` keyword** to enable real-time generation directly in the editor without needing to run the game.
- **Strong typing:** Always use static typing in GDScript (e.g., `var timer: Timer`, `func generate() -> void:`).
- **Event-driven:** Use Godot `Signal`s to notify generation completion (useful for triggering subsequent NavMesh baking).
