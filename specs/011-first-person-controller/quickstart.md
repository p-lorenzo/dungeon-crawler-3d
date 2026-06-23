# Quickstart Validation Guide: First-Person Controller

This guide describes how to verify the First-Person Controller feature for testing generated dungeons.

## Prerequisites
- Godot Engine 4.6.
- A generated dungeon layout.

## Running the Verification Test

Since the First-Person Controller requires user input (mouse look and WASD movement), the primary validation method is manual playtesting.

To launch the playtest scene:
1. Open the project in the Godot Editor.
2. Run the main demo scene: `demo/demo_main.tscn`.
3. The dungeon will generate automatically, and the first-person player will spawn at the entrance.

### Verification Scenarios

- **Scenario 1: Spawning at Entrance**
  - **Steps**: Start `demo/demo_main.tscn`.
  - **Expected Outcome**: The player camera spawns exactly at the position of the Entrance room (index 0 in `DungeonGraph.placements`).

- **Scenario 2: Mouse Capture & Escape Lock**
  - **Steps**: Click inside the window to lock the cursor. Move mouse to look around. Press `Escape` key.
  - **Expected Outcome**: Mouse look is responsive when locked. Pressing `Escape` releases the mouse cursor and allows clicking other windows/UI.

- **Scenario 3: Movement and Physics Collision**
  - **Steps**: Move the player using WASD or arrow keys. Walk into walls and doorways.
  - **Expected Outcome**: The player slides smoothly along walls and is blocked by doorways or obstacles, without clipping through or falling out of bounds.

- **Scenario 4: Headless Validation Script**
  - **Steps**: Run the headless check script to verify player scene structure and script static types:
    ```bash
    godot --headless -s demo/test_player_controller_structure.gd
    ```
  - **Expected Outcome**: The script verifies that the player scene exists, uses `CharacterBody3D`, has a `CollisionShape3D`, and doesn't throw parser errors.
