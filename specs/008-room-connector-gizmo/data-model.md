# Data Model: Room Connector Editor Gizmos

This document defines the properties and attributes used by the room connector editor gizmo system.

## 1. RoomConnector3D (Scene Node Updated Properties)

The `RoomConnector3D` custom node is updated with new properties defining the physical dimensions of the doorway aperture.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `aperture_width` | `float` | `2.0` | Width of the doorway frame. Must be validated to be at least `0.1` to prevent negative or zero size. |
| `aperture_height` | `float` | `2.5` | Height of the doorway frame. Must be validated to be at least `0.1` to prevent negative or zero size. |

Other properties from previous specifications (`connection_type`, `is_locked`, `key_id`, `doorway_scene`, `blocker_scene`) remain unchanged.

---

## 2. Editor Drawing Data

The `RoomConnectorGizmoPlugin` uses the property configuration of `RoomConnector3D` to calculate viewport drawing segments.

### Rectangle Segments (Local Coordinates)
A set of 4 lines representing the door frame.
- Line 1 (Floor): `(-aperture_width / 2, 0, 0)` to `(aperture_width / 2, 0, 0)`
- Line 2 (Right Upright): `(aperture_width / 2, 0, 0)` to `(aperture_width / 2, aperture_height, 0)`
- Line 3 (Header): `(aperture_width / 2, aperture_height, 0)` to `(-aperture_width / 2, aperture_height, 0)`
- Line 4 (Left Upright): `(-aperture_width / 2, aperture_height, 0)` to `(-aperture_width / 2, 0, 0)`

### Exit Arrow Segments (Local Coordinates)
A main directional line and 4 arrowhead fin lines showing the exit direction.
- Main Line: `(0, 0, 0)` to `(0, 0, 1.0)`
- Arrowhead Line 1 (Left): `(0, 0, 1.0)` to `(-0.15, 0, 0.85)`
- Arrowhead Line 2 (Right): `(0, 0, 1.0)` to `(0.15, 0, 0.85)`
- Arrowhead Line 3 (Up): `(0, 0, 1.0)` to `(0, 0.15, 0.85)`
- Arrowhead Line 4 (Down): `(0, 0, 1.0)` to `(0, -0.15, 0.85)`

### Color Mapping
The drawing color is determined dynamically using the existing `RoomConnector3D._get_gizmo_color()` function:
- Default: `Color.GRAY` (empty/unconfigured connection type)
- Standard Door (`"standard_door"`): `Color.SKY_BLUE`
- Large Gate (`"large_gate"`): `Color.ORANGE`
- Custom/Other Connection Type: `Color.GREEN_YELLOW`
- Locked (`is_locked = true`): `Color.MAGENTA` (overrides connection type)
