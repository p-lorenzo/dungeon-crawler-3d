# Class Contract: ConnectorMatcher

Calculates alignments and matches compatible connetor ports.

## Public Interface

### `find_matching_connector`
```gdscript
func find_matching_connector(room_scene: PackedScene, target_connector_type: String) -> int
```
Scans the room scene for a connector matching the target connection type string. Returns the 0-based index of the matching connector, or `-1` if none is found.

### `get_connectors`
```gdscript
func get_connectors(room_scene: PackedScene) -> Array[Transform3D]
```
Returns an array of local transforms for all `RoomConnector3D` nodes found in the room scene.

### `get_connector_types`
```gdscript
func get_connector_types(room_scene: PackedScene) -> Array[String]
```
Returns an array of connection type strings for all connectors in the room scene.

### `compute_alignment_transform`
```gdscript
func compute_alignment_transform(connector_a_world: Transform3D, connector_b_local: Transform3D) -> Transform3D
```
Computes the world-space target `Transform3D` for placing Room B such that its Connector B (`connector_b_local`) aligns face-to-face with the already placed Connector A (`connector_a_world`).

#### Rotation Alignment Details:
1. Rotate `connector_a_world`'s basis by 180 degrees around Y:
   $$T_{target\_basis} = T_{connector\_a\_basis} \times R_{Y}(180)$$
2. Multiply by the inverse of `connector_b_local`:
   $$T_{room\_b\_world} = T_{target} \times (T_{connector\_b\_local})^{-1}$$
This generic alignment naturally supports turns and curves of any angle, including 90-degree offsets.
