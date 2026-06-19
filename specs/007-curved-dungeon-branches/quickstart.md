# Quickstart Validation Guide: Curved Dungeon Branches

This guide defines the end-to-end integration scenario used to prove that the Curved Dungeon Branches feature works correctly.

## Prerequisites
- Godot 4.6 installed.
- Access to the headless Godot executable.

## Running the Verification Test
An integration test script `demo/test_curved_branches.gd` will be created to configure a dungeon layout using 90-degree corner and T-junction prefabs, run the generation, and verify the resulting geometry and paths.

Run the test suite headlessly from the repository root:
```bash
/home/plorenzo/Documenti/Godot/Godot_v4.6.3-stable_linux.x86_64 --headless -s demo/test_curved_branches.gd
```

## Validation Scenarios

### Scenario 1: Corner Room Placement on Main Path
- **Setup**: Configures `main_path_length = 5`, corridors pool containing only `corner.tscn` (which has connectors at a 90-degree angle).
- **Execution**: Calls `generator.generate()`.
- **Expected Outcome**:
  - Generation completes successfully.
  - Placements are aligned correctly using the computed Y-rotations (e.g. 90 or 270 degrees).
  - Connectors align face-to-face with zero gaps.
  - Path traversability from Entrance to Boss is verified as valid.

### Scenario 2: Overlap Avoidance and Backtracking
- **Setup**: Configures a layout that curves back into itself (forcing a collision).
- **Execution**: Triggers generation.
- **Expected Outcome**:
  - Bounding box checks correctly detect the collision.
  - The generator backtracks, reverts the overlapping placements, and either resolves it by placing a straight room or exits cleanly with the expected collision failure rather than spawning overlapping rooms.
