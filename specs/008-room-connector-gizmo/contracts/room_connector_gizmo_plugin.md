# Class Contract: RoomConnectorGizmoPlugin & RoomConnector3D Updates

This document describes the interface contracts for the custom editor gizmo plugin and updates to the `RoomConnector3D` node.

## 1. RoomConnectorGizmoPlugin

A custom editor plugin class that extends `EditorNode3DGizmoPlugin` to draw 3D viewport helper lines for `RoomConnector3D` nodes in the editor.

### Base Class
`EditorNode3DGizmoPlugin`

### Overridden Methods

#### `_get_gizmo_name`
```gdscript
func _get_gizmo_name() -> String
```
Returns the unique name of the gizmo plugin for Godot's internal registry.
- **Returns**: `"RoomConnector3D"`

#### `_has_gizmo`
```gdscript
func _has_gizmo(spatial: Node3D) -> bool
```
Determines if a given node is handled by this gizmo plugin.
- **Parameters**: `spatial: Node3D` — the spatial node to check.
- **Returns**: `true` if `spatial` is an instance of `RoomConnector3D`, otherwise `false`.

#### `_redraw`
```gdscript
func _redraw(gizmo: EditorNode3DGizmo) -> void
```
Draws the custom rectangular doorway frame and the exit arrow pointing along the local +Z axis.
- **Parameters**: `gizmo: EditorNode3DGizmo` — the gizmo helper instance being redrawn.
- **Behavior**:
  1. Retrieve the corresponding node: `var node := gizmo.get_node_3d() as RoomConnector3D`.
  2. Clear the previous drawing: `gizmo.clear()`.
  3. Query properties: `aperture_width`, `aperture_height`, and `_get_gizmo_color()`.
  4. Build line segment coordinate arrays (in local space).
  5. Fetch/create the editor material configured to use vertex colors.
  6. Call `gizmo.add_lines()` to commit the rectangle outline and the directional arrow to the viewport cache.

---

## 2. RoomConnector3D (Updated Methods)

### Public Properties Added/Modified

#### `aperture_width`
```gdscript
@export var aperture_width: float = 2.0
```
Width of the door aperture. Changes triggers `update_gizmos()`. Clamped to `[0.1, inf)`.

#### `aperture_height`
```gdscript
@export var aperture_height: float = 2.5
```
Height of the door aperture. Changes triggers `update_gizmos()`. Clamped to `[0.1, inf)`.

### Internal Methods

#### `update_gizmos`
```gdscript
func update_gizmos() -> void
```
Built-in `Node3D` method that forces the editor to redraw the node's associated gizmos. Called from property setters when running in editor tool mode.
