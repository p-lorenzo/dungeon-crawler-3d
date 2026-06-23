# Dungeon Crawler 3D

[![Godot Engine](https://img.shields.io/badge/Godot-4.6%2B-blue?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Dungeon Crawler 3D** is a powerful procedural 3D dungeon generator plugin for Godot Engine 4.x. Inspired by Unity's DunGen, this system dynamically assembles complex level layouts from predefined room modules (saved as `PackedScene`) joined together through compatible connector ports.

The generation engine executes all spatial reasoning, logical bounding box collision checks, path validation, and lock-and-key distribution entirely in memory before instantiating any node in the SceneTree, ensuring high performance and softlock-free layouts.

---

## 🌟 Features

*   **Connector-Based Room Snapping:** Place matching connector nodes inside room scenes to let the generator automatically align, rotate, and snap rooms together.
*   **Editor Viewport Previews (`@tool`):** Build, view, and clear generated dungeon layouts directly in the Godot editor viewport with the click of an inspector button.
*   **Logical Collision Detection (AABB):** Computes room bounding boxes in memory to detect and prevent overlaps *before* scenes are instantiated.
*   **Lock & Key Solvability Analyzer:** Automatically places keys and locks based on topological path logic (BFS/DFS), ensuring that keys spawn in predecessor rooms accessible from the entrance.
*   **Weighted Prop Randomization:** Distributes weighted prop placeholders (`PropGroup3D`) with global and local spawn counts, seed-based RNG, and uniform distribution fallbacks.
*   **Unique Tile Injection:** Injects specific tiles (such as shops, quest checkpoints, or boss rooms) at targeted depth ranges along the main path or branch paths.
*   **Dynamic Navigation Mesh Adaptation:** Asynchronously bakes navigation mesh data across the generated dungeon geometry at runtime (or synchronously inside the editor).
*   **Demo & Playable Character:** Includes a fully functional, statically typed First-Person Controller (FPC) with mouse capture to immediately playtest your generated levels.

---

## 📂 Repository Structure

*   `addons/dungeon_crawler_3d/`: The self-contained Godot plugin. **This is the folder you copy into your project.**
    *   `core/`: Pure GDScript computational logic (AABB collision, graph, path validation, lock/key assignments).
    *   `nodes/`: Custom `Node3D` nodes exposed to the editor (`DungeonGenerator3D`, `RoomConnector3D`, `KeySpawnPoint3D`, `PropGroup3D`, etc.).
    *   `resources/`: Serializable custom `Resource` configurations (`DungeonConfig`, `RoomData`, `TileInjectionRule`).
*   `demo/`: A sample playground containing pre-made rooms, configs, test suites, and the first-person controller demo.
*   `specs/`: Detailed design specifications, planning, and research documents.

---

## ⚙️ Installation

1.  Download the latest release or clone this repository.
2.  Copy the `addons/dungeon_crawler_3d` directory into the root of your Godot project's `addons/` directory (create it if it does not exist).
3.  In Godot, open **Project -> Project Settings -> Plugins** and check the **Enable** box next to **Dungeon Crawler 3D**.

---

## 🚀 Quickstart Guide

### 1. Design your Room Scenes
Create new scenes extending `Node3D`. Instantiation boundaries are computed from the room's geometry.
*   Place `RoomConnector3D` nodes at doorways or openings. 
*   Configure the connector type name (e.g., `"standard"`, `"narrow"`) and orientation (connectors face the positive Z-axis direction).
*   Optional: Place `PropGroup3D` nodes to act as prop spawning anchors, and `KeySpawnPoint3D` nodes to define potential key locations.

### 2. Configure Dungeon Settings
Create a `DungeonConfig` resource in your inspector:
*   Define the `entrance_pool`, `boss_pool`, `corridor_pool`, and `junction_pool` using your room scene resources.
*   Set the target path length, branching parameters, and random seeds.
*   Optional: Add `TileInjectionRule` definitions for special rooms.

### 3. Add the Generator Node
*   Add a `DungeonGenerator3D` node to your scene.
*   Assign your `DungeonConfig` resource to the generator's `Config` property.
*   Click **Generate** in the inspector to preview the dungeon. Click **Clear** to wipe it.

### 4. Setup Navigation Mesh (Optional)
*   Add a `NavigationRegion3D` to your scene.
*   Add a `DungeonNavMeshAdapter3D` child node and link it to your `DungeonGenerator3D` and `NavigationRegion3D`.
*   Bakes will run automatically after successful generations.

---

## 🧪 Running Tests

We maintain a suite of headless validation tests. You can run all test suites headlessly using the Godot CLI from the project root:

```bash
for test in demo/test_*.gd; do godot --headless -s $test; done
```

Tests include:
*   `test_doorway_blockers.gd`: Validates doorway/wall blocker placement logic.
*   `test_lock_key.gd`: Validates topological solvability of lock & key generation.
*   `test_navmesh_baking.gd`: Validates dynamic NavigationMesh baking.
*   `test_player_controller_structure.gd`: Validates First-Person Controller structure and node configuration.
*   `test_prop_randomizer.gd`: Validates seed-based weighted prop selection and clamping.
*   `test_random_connector_selection.gd`: Validates winding labyrinth-style layout routing.
*   `test_room_connector_gizmo.gd`: Validates room connector gizmo plugin.
*   `test_tile_injection.gd`: Validates unique room placements along paths.

---

## 🤝 Contributing

We welcome pull requests and bug reports! To submit a contribution:

1.  Fork the repository.
2.  Create a branch for your changes (e.g., `feature/cool-new-feature` or `bugfix/issue-description`).
3.  **Strict Coding Requirements:**
    *   **GDScript Static Typing:** Every single variable, parameter, and return value must be explicitly typed.
    *   **Plugin Isolation:** Keep plugin-related features under `addons/dungeon_crawler_3d/` and tests/demos in `demo/`. Never leak game assets into the plugin folder.
    *   **Language:** All code comments, file names, commits, and documentation must be in English.
4.  Run the test suites (as described in [Running Tests](#-running-tests)) to verify your changes did not break existing features.
5.  Open a Pull Request describing your implementation and validation details.

---

## 📄 License

This project is licensed under the MIT License. See `LICENSE` for details.
