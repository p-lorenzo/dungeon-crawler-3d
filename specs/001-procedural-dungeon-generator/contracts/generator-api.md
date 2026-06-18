# Generator API Contract

**Feature**: 001-procedural-dungeon-generator
**Date**: 2026-06-18

This document defines the public interface contract for `DungeonGenerator3D`. These are the guarantees that consumers (demo scene, NavMesh baker, external tools) can rely on.

---

## Signals

### `generation_completed(dungeon_root: Node3D)`

Emitted when dungeon generation succeeds.

| Parameter | Type | Description |
|-----------|------|-------------|
| `dungeon_root` | `Node3D` | Parent node containing all instantiated room scenes. Children are `Node3D` instances of the PackedScene from each placed RoomData. |

**Contract**:
- The signal is emitted AFTER all rooms are added to the SceneTree.
- `dungeon_root` is a child of `DungeonGenerator3D`.
- All rooms in `dungeon_root` have valid `owner` set for packed scene serialization.
- The room at `dungeon_root.get_child(0)` is the entrance; the last child of the main path is the boss room (traversal order may differ from child order if branches exist).
- A traversable path exists from entrance to boss through connector-matched doorways.

### `generation_failed(reason: String)`

Emitted when dungeon generation fails.

| Parameter | Type | Description |
|-----------|------|-------------|
| `reason` | `String` | Human-readable explanation of the failure. |

**Contract**:
- The signal is emitted after cleanup. No partial dungeon remains in the SceneTree.
- Possible `reason` values: `"Empty room pool"`, `"No entrance room configured"`, `"No boss room configured"`, `"Cannot satisfy main path length"`, `"Cannot satisfy branch count"`, `"Exhausted backtracking attempts"`, `"Missing PackedScene reference: <path>"`, `"No matching connectors found"`.

---

## Public Methods

### `generate() -> void`

Triggers dungeon generation. Callable from editor inspector button or programmatically.

**Preconditions**:
- `config: DungeonConfig` is assigned and valid.
- Generator is not already generating (idempotent: calling while generating is a no-op).

**Postconditions**:
- On success: emits `generation_completed(dungeon_root)`.
- On failure: emits `generation_failed(reason)`.

**Contract**:
- Synchronous execution (blocks editor thread during generation).
- No side effects on failure.
- Repeatable: calling `generate()` after `clear()` produces a new dungeon (seed-dependent).

### `clear() -> void`

Removes all generated room instances from the SceneTree.

**Preconditions**: None (safe to call even if no dungeon exists).

**Postconditions**:
- All children of the generator node (except the generator's own persistent children like config preview) are freed.
- Generator returns to pre-generation state; `config` is preserved.

**Contract**:
- Idempotent: calling `clear()` twice is safe.
- Does not modify `DungeonConfig` or any Resource.

---

## Public Properties

### `config: DungeonConfig`

| Aspect | Detail |
|--------|--------|
| Type | `DungeonConfig` (Resource) |
| Accessibility | Read/write in inspector and code |
| Default | `null` |

**Contract**:
- Setting `config` to `null` disables generation; `generate()` with null config emits `generation_failed("No configuration assigned")`.
- Changes to `config` take effect on the next `generate()` call; they do not affect an already-generated dungeon.

---

## Editor Inspector

| Section | Control | Action |
|---------|---------|--------|
| DungeonGenerator3D | `[Generate]` button | Calls `generate()` |
| DungeonGenerator3D | `[Clear]` button | Calls `clear()` |
| DungeonGenerator3D | `config` property | Drag-and-drop a `DungeonConfig` resource |

---

## Error Handling Contract

| Condition | Behavior |
|-----------|----------|
| `config == null` | `generation_failed("No configuration assigned")` |
| Empty entrance or boss pool | `generation_failed("No entrance/boss room configured")` |
| Missing PackedScene reference | `generation_failed("Missing PackedScene reference: <path>")` — detected before generation starts |
| Generation exhausts attempts | `generation_failed("Exhausted backtracking attempts")` |
| Partial success (some branches not placed) | `generation_completed` with as many rooms as possible + `generation_failed` as secondary signal? **Decision deferred** — see note. |

**Note on partial success**: The spec edge case says "place as many as possible and signal partial-success or fallback". The contract for this scenario is deferred to implementation. Options: (a) dual-signal (completion + a `generation_warning` signal), (b) `generation_completed` with a `partial_success: bool` property on the generator. Either way, the `dungeon_root` must contain a valid start→boss path.
