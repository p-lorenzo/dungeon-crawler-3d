# Research: Procedural Dungeon Generator

**Feature**: 001-procedural-dungeon-generator
**Date**: 2026-06-18

## 1. Godot EditorPlugin Architecture

**Decision**: Use `EditorPlugin` base class with `@tool` annotation on custom nodes.

**Rationale**: Godot's `EditorPlugin` (`addons/<name>/plugin.cfg` + entry script) is the standard mechanism for editor extensions. The entry script (`dungeon_crawler_3d.gd`) registers custom nodes via `add_custom_type()` and custom resources via `add_custom_resource_type()`. `@tool` on `DungeonGenerator3D` enables inspector buttons (`generate()`, `clear()`) to execute in the editor without entering play mode.

**Alternatives considered**:
- `EditorScript`: Single-shot execution, no persistent node — rejected because generator must live as a scene node with persistent configuration.
- `EngineDebugger` plugin: Not applicable to level design tools.

**Key references**:
- Godot 4.x `EditorPlugin` API: `_enter_tree()`, `_exit_tree()`, `add_custom_type()`, `remove_custom_type()`
- `plugin.cfg` format: `[plugin] name`, `description`, `author`, `version`, `script`

## 2. @tool Script Execution & Editor Updates

**Decision**: Mark `DungeonGenerator3D` and `RoomConnector3D` with `@tool`. Generation runs synchronously in the editor thread; scene updates use `EditorInterface.get_edited_scene_root()` context.

**Rationale**: `@tool` makes the script run both in-editor and at runtime. Generation is synchronous (no `await`) because it's a compute-bound operation, not I/O-bound. Editor integration requires `Engine.is_editor_hint()` guards for debug-only logic. The generated rooms are children of the generator node, appearing in the editor viewport immediately.

**Alternatives considered**:
- `EditorPlugin._handles()` with custom gizmo: Overkill for v1; the inspector button approach is simpler and matches DunGen's workflow.
- Async generation via `WorkerThreadPool`: Rejected for v1 because dungeon generation is fast enough (3-5s targets) and async adds complexity with SceneTree thread-safety rules.

**Key references**:
- Godot `@tool` documentation: scripts must avoid infinite loops in `_process()`
- `Engine.is_editor_hint()` for editor-only behavior
- SceneTree mutations from `@tool` scripts: `owner` must be set for packed scenes

## 3. Godot Resource Serialization

**Decision**: `DungeonConfig` and `RoomData` extend `Resource`. Parameters use `@export` annotations for inspector visibility. Assets saved as `.tres` files.

**Rationale**: `Resource` is Godot's serializable data container. `@export var` exposes fields in the inspector. `.tres` is human-readable text format, enabling version control diffing. Resources can be saved/loaded via `ResourceSaver`/`ResourceLoader`.

**Alternatives considered**:
- JSON config files: Rejected — no inspector integration, no type safety, no scene references.
- `ConfigFile` built-in: Rejected — less flexible than custom Resource classes.
- Binary `.res` format: Deferred — `.tres` preferred for VCS friendliness during development.

**Key references**:
- `Resource._init()`, `ResourceSaver.save()`, `ResourceLoader.load()`
- `@export var pool: Array[RoomData]` for typed arrays in Godot 4.x
- `@export_category` for inspector grouping

## 4. AABB Collision Detection

**Decision**: Use AABB (axis-aligned bounding box) overlap tests on room bounding volumes before SceneTree instantiation.

**Rationale**: AABB is O(n) per placement check against already-placed rooms. Rooms are axis-aligned (assumption) so AABB is exact, not an approximation. Godot provides `AABB.intersects()` and `AABB.encloses()` in core. The check runs in the graph-building phase, before any `add_child()` calls.

**Alternatives considered**:
- Physics-based collision (`PhysicsDirectSpaceState3D`): Rejected — requires instantiation into SceneTree, violating Constitution II.
- Octree spatial partitioning: Deferred to optimization phase if 50-room pools show performance issues.
- OBB (oriented bounding box): Rejected — rooms are axis-aligned with 90-degree rotation increments only.

**Key references**:
- Godot `AABB` class: `AABB(position, size)`, `.intersects(other)`, `.grow(amount)`
- Spatial hashing as future optimization

## 5. Dungeon Graph & Backtracking Algorithm

**Decision**: Represent the dungeon as a directed graph where nodes = placed rooms and edges = connector pairings. Use iterative backtracking with explicit stack.

**Rationale**: The graph naturally models room connectivity. Backtracking (FR-014: 1-step local undo) is implemented by popping the last placement from the stack and trying the next candidate. An explicit stack avoids recursion depth limits for large dungeons. `max_generation_attempts` limits retries per position.

**Alternatives considered**:
- Recursive depth-first placement: Rejected — stack overflow risk for large dungeons; harder to implement backtracking limits.
- Wave Function Collapse (WFC): Rejected — overkill for v1; WFC excels at tile-based generation but the room+connector model is simpler.
- Markov chain generation: Rejected — doesn't guarantee connectivity constraints.

**Key references**:
- Standard DFS with backtracking for constraint satisfaction problems
- Godot `Array` as stack (`.append()`, `.pop_back()`)

## 6. Connector Alignment Math

**Decision**: Compute world transform to align connector A's position with connector B's position, with opposite facing directions. Rotation = connector A's rotation rotated 180° around Y axis to face connector B's direction.

**Rationale**: Given connector A at local transform (pos_A, rot_A) and connector B at (pos_B, rot_B) in their respective room spaces, the room being placed needs a world transform T such that: `T * pos_A = world_pos_B` and `T * rot_A = rot_B * ROT_180_Y`. Godot's `Transform3D` supports this via `looking_at()` and basis manipulation.

**Alternatives considered**:
- Snap-to-grid alignment: Rejected — connectors have arbitrary positions, not grid-aligned.
- Manual alignment (designer rotates room in inspector): Rejected — violates "simpler than DunGen" goal; automation is key.

**Key references**:
- Godot `Transform3D`: `Transform3D(Basis, origin)`, `Basis.looking_at()`
- `Transform3D * Transform3D` composition for chaining room transforms

## 7. Weighted Random Selection with Cooldown

**Decision**: Track recent placements in a fixed-size FIFO queue. During selection, multiply each candidate's weight by a penalty factor (0.0 to 1.0) based on how recently it appeared in the queue.

**Rationale**: Simple cooldown: weight = original_weight * (1.0 - cooldown_factor) if room is in the recent queue, else weight = original_weight. Cooldown factor and queue size are internal constants (not exposed in v1). The random seed (FR-011) is passed to Godot's `RandomNumberGenerator` for reproducibility.

**Alternatives considered**:
- Weight with exclusion: Rooms in recent-N are excluded entirely — rejected because it can exhaust the pool on small pools.
- Shuffle-bag: Generate a shuffled sequence, consume sequentially — rejected because it doesn't respect probability weights.

**Key references**:
- Godot `RandomNumberGenerator` with `.seed` property
- `randf_weighted(weights: Array[float])` — not built-in; implement manually with cumulative distribution

## 8. Godot Signal Patterns

**Decision**: Define signals on `DungeonGenerator3D`: `generation_completed(dungeon_root: Node3D)` and `generation_failed(reason: String)`. Connect downstream nodes via the editor's Node dock or programmatically.

**Rationale**: Signals follow Constitution III. `generation_completed` passes the root node so consumers (e.g., NavMesh baker) can traverse the generated tree. `generation_failed` passes a human-readable string per FR-009.

**Alternatives considered**:
- Callbacks/callables: Rejected — less flexible than signals for editor-time connections.
- Inspector-visible event properties: Rejected — adds unnecessary complexity.

**Key references**:
- Godot `signal` keyword: `signal generation_completed(dungeon_root: Node3D)`
- `.emit()` method to fire signals
