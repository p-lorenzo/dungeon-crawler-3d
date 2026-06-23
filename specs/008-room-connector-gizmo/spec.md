# Feature Specification: Room Connector Editor Gizmos

**Feature Branch**: `008-room-connector-gizmo`

**Created**: 2026-06-23

**Status**: COMPLETE

**Input**: User description: "Vorrei aggiungere una feature, dove posiziono dei roomconnector vorrei che sia visibile un gizmo rettangolare che fa capire che quella é l'apertura, con una freccia che, perpendicolare alla porta, mostra l'uscita, in modo da posizionare il connector nella posizione giusta"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualizing RoomConnector3D Apertures in the Editor (Priority: P1)

As a dungeon designer, I want to see a rectangular wireframe frame at the position of each `RoomConnector3D` node in the 3D editor viewport, so that I can instantly visualize the size and boundaries of the doorway opening.

**Why this priority**: It is the core requirement of the feature. Visualizing the doorway opening is essential for correct positioning and layout alignment.

**Independent Test**:
1. Open a room scene in the Godot Editor.
2. Select or add a `RoomConnector3D` node.
3. Verify that a rectangular outline is rendered at the node's position.
4. Modify `aperture_width` and `aperture_height` in the Inspector, and confirm the outline resizes dynamically.

**Acceptance Scenarios**:

1. **Given** a `RoomConnector3D` node is present in the active scene in the editor, **When** viewed in the 3D viewport, **Then** a rectangular wireframe representing the door frame is drawn centered horizontally on the node (local X-axis) and resting on the local floor (local Y-axis from 0 to height).
2. **Given** a designer changes the `aperture_width` or `aperture_height` in the Inspector, **When** the editor redraws, **Then** the rectangular gizmo updates its dimensions immediately.

---

### User Story 2 - Visualizing Connection/Exit Direction (Priority: P1)

As a dungeon designer, I want a directional arrow pointing perpendicular to the doorway plane in the direction of the connection exit (local +Z axis), so that I can orient the connector correctly facing outward from the room.

**Why this priority**: Essential to avoid placing connectors backwards, which would break the procedural generation alignment.

**Independent Test**:
1. Select a `RoomConnector3D` node in the 3D viewport.
2. Verify that an arrow is drawn starting from the node origin and pointing along the +Z axis.
3. Rotate the node and verify that the arrow rotates with it.

**Acceptance Scenarios**:

1. **Given** a `RoomConnector3D` node, **When** viewed in the editor, **Then** a line arrow is drawn starting from the node's local origin (0, 0, 0) and pointing outward along the +Z axis.
2. **Given** a `RoomConnector3D` node is rotated in the editor, **When** looking at the viewport, **Then** the exit arrow remains aligned with the local +Z axis of the node.

---

### User Story 3 - Dynamic Gizmo Color Coding (Priority: P2)

As a dungeon designer, I want the rectangular gizmo and exit arrow to match the connection type's color coding and lock status, so that I can verify properties at a glance without inspecting individual nodes.

**Why this priority**: Improves productivity and reduces configuration errors by providing immediate visual feedback of connector properties.

**Independent Test**:
1. Select a `RoomConnector3D` node.
2. Change the `connection_type` to different values (e.g. "standard_door", "large_gate").
3. Toggle the `is_locked` boolean.
4. Verify that the gizmo colors update immediately to match the expected colors.

**Acceptance Scenarios**:

1. **Given** a `RoomConnector3D` with a specific connection type (e.g. sky blue for "standard_door"), **When** rendered in the editor, **Then** the gizmo uses the color defined by `_get_gizmo_color()`.
2. **Given** a `RoomConnector3D` node with `is_locked` set to true, **When** rendered, **Then** the gizmo is drawn in magenta, overriding the `connection_type` color.

---

### Edge Cases

- **Zero or Negative Dimensions**: If a designer inputs a negative or zero value for width or height, the gizmo could become invisible or cause drawing errors. The inspector must clamp the values to a positive minimum, and the drawing logic must handle invalid sizes gracefully.
- **Editor Performance**: If a room contains many connectors, drawing gizmo lines must not degrade Godot editor viewport performance. Lines must be drawn using optimized gizmo material APIs.
- **Unloaded/Disabled Plugin**: When the plugin is disabled or uninstalled, the custom gizmo plugin must be correctly cleaned up and removed from the editor to avoid script errors.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `RoomConnector3D` MUST export `aperture_width` (float, default `2.0`) and `aperture_height` (float, default `2.5`) properties. These properties MUST be validated or clamped to be at least `0.1` to prevent zero or negative dimensions.
- **FR-002**: A custom `EditorNode3DGizmoPlugin` subclass named `RoomConnectorGizmoPlugin` (or similar) MUST be implemented to handle drawing the gizmos for `RoomConnector3D` nodes.
- **FR-003**: The gizmo plugin MUST register itself with the editor on plugin activation and unregister on deactivation, ensuring clean lifecycle management.
- **FR-004**: The gizmo plugin MUST draw a rectangular shape representing the aperture:
  - Width: Centered horizontally from `-aperture_width / 2` to `+aperture_width / 2` along the local X-axis.
  - Height: Extending vertically from `Y = 0` to `Y = aperture_height`.
  - Depth: Coinciding with the local `Z = 0` plane.
- **FR-005**: The gizmo plugin MUST draw a directional arrow starting at `(0, 0, 0)` and pointing along the local `+Z` axis with a minimum length of `1.0` and a visible arrowhead at the tip.
- **FR-006**: The gizmo plugin MUST query the color of the `RoomConnector3D` node via `_get_gizmo_color()` and render the lines using this color.
- **FR-007**: Modifying `aperture_width`, `aperture_height`, `connection_type`, or `is_locked` in the inspector MUST trigger `update_gizmos()` to refresh the viewport presentation in real time.

### Key Entities

- **`RoomConnector3D`**: The custom spatial node representing entry/exit points, now holding aperture size configuration.
- **`RoomConnectorGizmoPlugin`**: The editor plugin responsible for drawing the rectangular frame and directional arrow in the editor viewport.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Rectangular outline and arrow gizmo render correctly for 100% of placed `RoomConnector3D` nodes in the editor viewport.
- **SC-002**: Gizmo changes color instantly (within 100ms) upon modifying `connection_type` or `is_locked` in the Inspector.
- **SC-003**: The editor plugin activates and deactivates without throwing any errors or leaking gizmo resources in the editor console logs.

## Assumptions

- **Line Representation**: The rectangular frame is drawn as a wireframe outline (lines) rather than filled solid faces to keep the viewport clean and unobstructed.
- **Origin Alignment**: The node's local origin represents the center-bottom of the doorway (on the floor level).
- **Z-Axis Direction**: The local +Z axis is defined as pointing outward (exit direction) from the room, matching the project's coordinate convention.
- **Viewport Only**: The gizmo and arrow are strictly editor-only visualization tools and are not loaded or rendered when the game is running.
