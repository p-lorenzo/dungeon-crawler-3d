# Feature Specification: NavMesh Baking Adapter

**Feature Branch**: `005-navmesh-baking`

**Created**: 2026-06-18

**Status**: Draft

**Input**: User description: "specs/proposals/006-navmesh-baking-adapter.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Designer Attaches and Configures Adapter (Priority: P1)

Dungeon designers can add a `DungeonNavMeshAdapter3D` node to their scene, configure properties (like navigation layers and parsing geometry source), and link it to a target `NavigationRegion3D` in the inspector.

**Why this priority**: It is the primary setup step that integrates the dynamic layout generator with Godot's built-in pathfinding.

**Independent Test**: Add the adapter to a test scene and configure target region paths and options, verifying they persist in the inspector.

**Acceptance Scenarios**:

1. **Given** a scene with a `DungeonGenerator3D` node, **When** a designer adds a `DungeonNavMeshAdapter3D` node, **Then** they can link a `NavigationRegion3D` reference using the Inspector.
2. **Given** a `DungeonNavMeshAdapter3D` node, **When** the designer toggles `use_collision_geometry` and modifies `navigation_layers`, **Then** the parameters update on the node correctly.

---

### User Story 2 - Automatic Post-Generation Baking at Runtime (Priority: P1)

During gameplay, immediately after a procedural dungeon finishes generating, the adapter intercepts the completion signal, automatically bakes the NavMesh, and allows AI agents to walk through the layout.

**Why this priority**: Core functionality needed to support navigation and pathfinding in dynamic procedural levels.

**Independent Test**: Generate a dungeon at runtime, spawn an AI enemy, and verify it successfully computes a path to the player immediately.

**Acceptance Scenarios**:

1. **Given** a running game with a dynamic dungeon setup, **When** `DungeonGenerator3D` finishes instantiating the rooms and emits `generation_completed`, **Then** the adapter catches the signal and triggers a re-bake of the linked `NavigationRegion3D`'s mesh.
2. **Given** a freshly baked navigation mesh, **When** an AI agent requests a path from room A to room B, **Then** the NavigationServer successfully returns a valid navigation path.

---

### User Story 3 - Collision-based vs. Visual Mesh Baking (Priority: P2)

Level designers can choose whether to bake navigation zones based on complex visual meshes or simpler collision shapes to optimize performance and compile cleaner paths.

**Why this priority**: Crucial optimization feature. Navmesh generation based on collision boxes is significantly faster and less error-prone than parsing high-poly render meshes.

**Independent Test**: Set `use_collision_geometry` to true, generate a dungeon, and visually verify that the navigation mesh outline aligns with static physics bodies rather than visual rendering.

**Acceptance Scenarios**:

1. **Given** a room containing high-detail static mesh assets but simple box colliders, **When** `use_collision_geometry` is set to `true`, **Then** the baked Walk zones only capture physics collision shapes, ignoring high-frequency rendering geometry.

---

### Edge Cases

- **Empty NavMesh Bakes**: What happens when the generator creates a dungeon layout with disconnected rooms or no walk surfaces? The baking process must fail gracefully without crash.
- **Mid-Game Regeneration**: If a dungeon is regenerated while AI agents are actively pathfinding, the system must update walk paths without causing navigation agent errors.
- **Asynchronous Bake Thread Crashes**: If thread-based baking fails or is interrupted by scene transitions, the system must clean up navigation threads cleanly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a custom `DungeonNavMeshAdapter3D` node subclassing `Node`.
- **FR-002**: The `DungeonNavMeshAdapter3D` class MUST export `navigation_region` (NodePath or reference), `bake_on_completed: bool` (default: true), `use_collision_geometry: bool` (default: false), and `navigation_layers: int` bitmask.
- **FR-003**: The adapter MUST connect to and listen for the `generation_completed(dungeon_root: Node3D)` signal from `DungeonGenerator3D`.
- **FR-004**: Upon receiving the completion signal, the adapter MUST update the parsing source on the target `NavigationRegion3D` to target the generated dungeon's root node.
- **FR-005**: The adapter MUST trigger Godot's NavigationMesh baking logic to rebuild the walk zone bounds.
- **FR-006**: The system MUST handle asynchronous vs. synchronous baking by performing the bake on a background thread by default (passing `on_thread = true` to the NavigationServer baking API) to prevent runtime frame hitches, while exposing a `bake_async: bool` (default: true) export property to allow synchronous main-thread baking when set to false.
- **FR-007**: The system MUST handle editor-time baking under `@tool` by automatically baking the navigation mesh and dynamically updating the editor viewport walk guides immediately when the generator completes an in-editor layout build.
- **FR-008**: The system MUST handle missing or unresolved navigation region references by automatically creating a new `NavigationRegion3D` node under the dungeon root node, configuring it with a default `NavigationMesh` resource, and baking the navigation mesh into it.

### Key Entities *(include if feature involves data)*

- **DungeonNavMeshAdapter3D**: A custom spatial node that monitors layout completion and manages navigation mesh compilation.
  - Attributes: `navigation_region: NavigationRegion3D`, `bake_on_completed: bool`, `use_collision_geometry: bool`, `navigation_layers: int`
- **NavigationRegion3D**: The standard Godot node that holds the baked `NavigationMesh` resource and manages local navigation bounds.
- **DungeonGenerator3D**: The layout builder node that emits completion signals.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Navigation paths must compile successfully across 100% of generated and connected rooms containing walk surfaces.
- **SC-002**: Performing a navigation mesh bake at runtime must not block the main thread for more than 16ms if asynchronous threaded baking is active.
- **SC-003**: The resulting NavigationMesh walk zones must accurately reflect traversable areas, with zero walk zone creation inside solid walls or blockers.
- **SC-004**: Transitioning between rooms must allow AI agents to navigate smoothly, computing a 10-room path in under 1ms on the NavigationServer.

## Assumptions

- Navigation settings (agent radius, height, max slope, max climb) are defined directly in the `NavigationMesh` resource assigned to the target `NavigationRegion3D`.
- All rooms contain collision shapes or mesh geometry compatible with Godot's NavigationServer3D baking tools.
- Generation completes when the node hierarchy is fully populated in memory or added to the active tree.
