# Research: Room Connector Editor Gizmos

This document captures the research and technical design decisions for implementing custom editor gizmos for `RoomConnector3D` nodes in Godot 4.6.

## Decision 1: EditorNode3DGizmoPlugin vs. Node3D _draw() / MeshInstance3D

### Selected Option
Create a custom `EditorNode3DGizmoPlugin` registered through the main `EditorPlugin`.

### Rationale
- **Godot Idiomatic Pattern**: In Godot 4, drawing editor-only viewport visualizations for custom nodes is done using `EditorNode3DGizmoPlugin`. This keeps the runtime node structure clean.
- **Clean SceneTree**: Using a gizmo plugin avoids spawning dummy `MeshInstance3D` or `ImmediateMesh` children inside `RoomConnector3D` which would clutter the scene tree and could accidentally leak into runtime builds.
- **Dynamic Property Updates**: When `update_gizmos()` is called on `RoomConnector3D`, Godot automatically invokes the gizmo plugin's `_redraw()` function, ensuring real-time editor feedback when properties change in the Inspector.

### Alternatives Considered
- **Spawning Debug Meshes at Runtime in Editor (`@tool`)**: We could spawn a `MeshInstance3D` child in `_ready()` and free it when running the actual game. This is simpler to implement but pollutes the designer's scene hierarchy in the Editor and can lead to serialization issues or stray nodes.
- **Draw using Debug Draw Class**: Using immediate-mode rendering inside `_process()` in the editor. This is highly inefficient and runs lines constantly, whereas gizmos are drawn once and cached by the Godot viewport renderer.

---

## Decision 2: Gizmo Drawing Shapes and Coordinates

### Selected Option
Draw a rectangular wireframe portal centered on the local X-axis (width) and standing on the local floor (height from `Y = 0` to `Y = height`), with an arrow pointing along the local `+Z` axis (length `1.0` meter).

```text
       Y (height)
       ▲
       ┌───────┐
       │   ▲   │
       │   │   │  ──▶ +Z (Forward Exit)
       │   o───┼─▶ X (width / 2)
      ─┴───────┴─
```

### Rationale
- **Aperture Outline**: Centering the width on X matches how doorway meshes are modeled in 3D packages (with the origin at the center-bottom of the door frame).
- **Exit Direction**: The procedural generator matches connectors pointing at each other. Thus, the arrow showing the connection exit must point outward from the room, which in this project's convention is the local `+Z` axis.
- **Line segments**:
  - Rectangle corners: `A = (-w/2, 0, 0)`, `B = (w/2, 0, 0)`, `C = (w/2, h, 0)`, `D = (-w/2, h, 0)`.
  - Arrow: From `(0, 0, 0)` to `(0, 0, 1.0)`.
  - Arrowhead: Lines from `(0, 0, 1.0)` to `(-0.15, 0, 0.85)`, `(0.15, 0, 0.85)`, `(0, 0.15, 0.85)`, and `(0, -0.15, 0.85)`.

---

## Decision 3: Custom Color Management

### Selected Option
Use the existing `RoomConnector3D._get_gizmo_color()` to retrieve the color, and pass it to the gizmo line drawing function `add_lines` using a single custom material configured with `use_vertex_color = true`.

### Rationale
- **Dry Code**: Leverages the current color configuration logic (sky blue for standard, orange for large, magenta for locked).
- **Single Material Performance**: By creating a single vertex-color-enabled material in the plugin `_init()`, we can draw any color of connector without creating multiple materials or updating material properties dynamically, which is better for performance.
- **Godot 4 API Compatibility**: In Godot 4:
  ```gdscript
  create_material("main", Color.WHITE, false, false, true) # true enables vertex color
  ```
  Then in `_redraw(gizmo)`:
  ```gdscript
  var color = room_connector._get_gizmo_color()
  var material = get_material("main", gizmo)
  gizmo.add_lines(lines, material, false, color)
  ```
