# Quickstart Validation Guide: Room Connector Editor Gizmos

This guide defines the procedures to verify that the Room Connector Editor Gizmos feature works correctly, both visually in the Godot Editor and programmatically via a headless test script.

## Prerequisites
- Godot 4.6 installed.
- Access to the headless Godot executable.

## Running the Programmatic Verification Test
A test script `demo/test_room_connector_gizmo.gd` will verify that `RoomConnector3D` correctly exposes the required properties, clamps inputs to valid bounds, and that `RoomConnectorGizmoPlugin` integrates with the connector type.

Run the test suite headlessly from the repository root:
```bash
Godot_v4.6.3-stable_linux.x86_64 --headless -s demo/test_room_connector_gizmo.gd
```

### Programmatic Validation Scenarios
- **Scenario 1**: Verify `RoomConnector3D` properties.
  - Instantiates `RoomConnector3D`.
  - Sets `aperture_width` to `3.5` and `aperture_height` to `4.0`.
  - Verifies that the properties return the correct values.
  - Sets negative values (e.g., `-1.0`) and verifies they are clamped to the minimum allowed value (`0.1`).
- **Scenario 2**: Verify `RoomConnectorGizmoPlugin` detection.
  - Instantiates `RoomConnectorGizmoPlugin` in tool mode.
  - Confirms `_get_gizmo_name()` returns `"RoomConnector3D"`.
  - Calls `_has_gizmo(connector)` and confirms it returns `true`.

---

## Visual Verification in the Godot Editor

To visually verify the gizmo rendering:

### Visual Validation Scenarios

#### Scenario 1: Basic Rendering & Dimensions
1. Open Godot and load the project.
2. Open any room prefab scene under `demo/rooms/` (e.g. `corner.tscn`).
3. Select a `RoomConnector3D` node in the Scene tree.
4. Verify that a gray rectangular frame and a gray directional arrow pointing along the local +Z axis are visible in the 3D viewport.
5. In the Inspector, change `aperture_width` to `3.0` and `aperture_height` to `2.0`.
6. Confirm that the rectangular outline immediately resizes to match these dimensions.

#### Scenario 2: Connection Type Color Matching
1. Select the `RoomConnector3D` node.
2. In the Inspector, change `connection_type` to `"standard_door"`.
3. Confirm that the outline and arrow instantly turn **sky blue**.
4. Change `connection_type` to `"large_gate"`.
5. Confirm that the outline and arrow instantly turn **orange**.

#### Scenario 3: Lock-State Coloring
1. Select the `RoomConnector3D` node.
2. Toggle the `is_locked` boolean in the Inspector to `true`.
3. Confirm that the outline and arrow instantly turn **magenta** (overriding the connection type color).
4. Toggle `is_locked` back to `false` and confirm it reverts to the connection type color.
