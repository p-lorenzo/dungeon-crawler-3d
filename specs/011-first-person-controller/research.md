# Research: First-Person Controller for Demo

This document details the research, technical decisions, and design patterns for implementing the first-person controller in the Dungeon Crawler 3D demo.

## Technical Decisions

### 1. File Location & Project Isolation
- **Decision**: Put all player-related assets under `demo/player/` (specifically `demo/player/player.tscn` and `demo/player/player.gd`).
- **Rationale**: To comply with the Constitution's **Plugin isolation** constraint, all demo-specific code must reside outside `plugins/dungeon_crawler_3d/`. Keeping it in `demo/player/` ensures the plugin itself remains completely clean.
- **Alternatives Considered**: 
  - Storing it under `plugins/dungeon_crawler_3d/demo/`: Rejected because the entire `plugins/dungeon_crawler_3d/` directory is packaged and published, and we do not want to bundle the demo player with the plugin.

### 2. Physics Body Choice
- **Decision**: Use `CharacterBody3D` with a `CollisionShape3D` (CapsuleShape3D) for the first-person controller.
- **Rationale**: `CharacterBody3D` is Godot's idiomatic node for user-controlled entities that require collision detection, sliding along walls, and stepping on floors without physics-driven forces causing jitter. It is fully compatible with Jolt Physics.
- **Alternatives Considered**:
  - `RigidBody3D`: Rejected because physics-driven movement is harder to tune, prone to jitter on grid boundaries, and less direct for standard first-person controls.

### 3. Entrance Spawning Mechanism
- **Decision**: Query the `DungeonGenerator3D` for its `active_graph`, retrieve the first placement's `world_transform` (which is the Entrance room), and place the player at its origin plus a safe vertical height offset (e.g. `Vector3(0, 1.0, 0)`).
- **Rationale**: In the dungeon graph, the placement at index 0 is always the `ENTRANCE` room. This is a clean, data-driven approach that doesn't rely on searching the SceneTree for specific node names.
- **Alternatives Considered**:
  - Spatial search for a node named `Entrance_0` in the scene tree: Rejected because it is less robust and couples the spawning logic to node naming conventions.

### 4. Input Configuration
- **Decision**: Define input mappings dynamically in the script if they do not exist in the project settings, or rely on Godot's default actions. Since the demo has a custom `project.godot`, we will define standard mouse capture and movement mappings in `project.godot` or configure them in code using `InputMap.add_action()`.
- **Rationale**: Ensures the demo runs out-of-the-box without requiring manual configuration from the user.
