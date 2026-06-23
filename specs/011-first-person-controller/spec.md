# Feature Specification: First-Person Controller for Demo

**Feature Branch**: `011-first-person-controller`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "vorrei aggiungere una feature alla demo per questo progetto/plugin, un controller in prima persona in modo da testare il dungeon generato in-game."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Explore Dungeons in First-Person (Priority: P1)

As a developer/playtester, I want to spawn as a first-person character in the generated dungeon and walk around using standard controls, so that I can visually inspect the dungeon layout, door connections, and prop placements from a player's perspective.

**Why this priority**: This is the core requirement. Testing dungeon layouts from a player's eye level is critical for verifying aesthetics and collision validity.

**Independent Test**: Run the demo scene, generate a dungeon, spawn the character, and verify you can look around with the mouse and walk through the corridors.

**Acceptance Scenarios**:

1. **Given** a generated dungeon in the demo scene, **When** play begins, **Then** the first-person controller character should spawn at the location of the dungeon entrance.
2. **Given** the play mode is active, **When** the user moves the mouse, **Then** the camera rotates to look around the environment.
3. **Given** the play mode is active, **When** the user presses WASD or arrow keys, **Then** the character moves forward, backward, left, or right relative to the camera direction.

---

### User Story 2 - Collision with Dungeon Geometry (Priority: P1)

As a playtester, I want the first-person controller to slide along walls and stand on floors without falling through or passing through dungeon boundaries, so that I can check for physical gaps, blockers, and collision accuracy.

**Why this priority**: Without collision, playtesting is ineffective since the player can clip through walls and walk in the void.

**Independent Test**: Walk into a wall or closed door and verify the character cannot walk through it. Walk on ramps or floors and verify the character stands and moves along them.

**Acceptance Scenarios**:

1. **Given** a generated dungeon with wall collision shapes, **When** the character walks directly into a wall, **Then** the character is blocked by the wall's collision geometry.

---

### User Story 3 - Mouse Capture and Cursor Lock Toggle (Priority: P2)

As a user, I want the mouse cursor to be captured and hidden while playing in first-person, and to be able to release it at any time to interact with UI buttons or close the window, so that the control scheme feels natural and matches standard PC gaming conventions.

**Why this priority**: Necessary for proper mouse look behavior and basic usability in editor/demo runtime tests.

**Independent Test**: Click on the game window to capture the mouse, look around, and then press a release key (e.g., Escape) to show the cursor again.

**Acceptance Scenarios**:

1. **Given** the first-person controller is active and capturing mouse movements, **When** the user presses the Escape key, **Then** the mouse cursor is released and becomes visible.
2. **Given** the mouse cursor is released, **When** the user clicks inside the viewport, **Then** the mouse cursor is captured again.

---

### Edge Cases

- **No Dungeon Generated**: If the user tries to play without generating a dungeon, the controller should either spawn at origin `(0,0,0)` on a default fallback floor, or wait for generation to complete before spawning.
- **Falling out of Dungeon**: If the character somehow clips through collision and falls into the void, a simple fallback (like respawning at the entrance when Y position falls below a certain threshold) should trigger.
- **Dynamic Dungeon Re-generation**: If the dungeon is re-generated while playing, the player should be safely repositioned to the new entrance spawn point.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The First-Person Controller MUST be implemented as a separate node/scene within the `demo/` folder, keeping it completely separated from the core plugin code.
- **FR-002**: The controller scene MUST use a `CharacterBody3D` (or equivalent physics body node) with a `CollisionShape3D` to interact with physics.
- **FR-003**: The controller MUST support standard movement inputs:
  - Forward: `W` or `Up Arrow`
  - Backward: `S` or `Down Arrow`
  - Strafe Left: `A` or `Left Arrow`
  - Strafe Right: `D` or `Right Arrow`
- **FR-004**: The controller MUST support mouse-look functionality to rotate the camera around both the yaw (horizontal) and pitch (vertical) axes, with pitch clamped to prevent flipping (e.g., between -85 and +85 degrees).
- **FR-005**: The controller MUST capture the mouse cursor when gameplay starts or when clicking the window, and MUST release it when pressing `Escape` or another designated key/action.
- **FR-006**: The controller MUST query the generated dungeon to find the entrance room's position and orientation to use as its initial spawn point.
- **FR-007**: The player's physics collisions MUST be compatible with the project's Jolt physics configuration.

### Key Entities

- **FirstPersonController**: The character node (extends `CharacterBody3D`) that handles user movement input, mouse capture, camera rotation, and physics movement.
- **DemoMain**: The main demo orchestrator scene that triggers dungeon generation and instantiates/spawns the first-person controller.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The character movement must feel smooth, running at the game's full framerate without jittering or stuttering.
- **SC-002**: Mouse movement mapping to camera look direction must feel responsive, with no visible input lag (less than 1 frame delay).
- **SC-003**: 100% of tested wall collisions must block the player without letting them clip outside the dungeon bounds.

## Assumptions

- **A-001**: The demo controls can use Godot's default project input map, or define them dynamically in code, to ensure it doesn't break if run on a clean project.
- **A-002**: The generated room scenes have collision shapes (static bodies) configured on floors and walls, allowing the character body to collide with them.
- **A-003**: The controller is only included in the `demo/` source directory, ensuring the publishable `plugins/dungeon_crawler_3d/` package remains clean and light.
