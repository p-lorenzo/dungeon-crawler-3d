# Quickstart Guide: Procedural Dungeon Generator

**Feature**: 001-procedural-dungeon-generator
**Date**: 2026-06-18

This guide walks through validating the dungeon generator end-to-end using the demo scene. No implementation code — just the steps, commands, and expected outcomes.

---

## Prerequisites

- Godot 4.6 installed (Linux, Windows, or Mac)
- Project opened in Godot editor: `godot -e project.godot` from repo root
- Plugin enabled: Project → Project Settings → Plugins → enable "Dungeon Crawler 3D"
- 3+ room scenes created with `RoomConnector3D` nodes (see "Creating Room Scenes" below)

---

## Creating Room Scenes (One-Time Setup)

1. Create a new 3D scene: Scene → New Scene → 3D Scene
2. Add geometry (MeshInstance3D, CollisionShape3D) to define the room's physical bounds — keep it axis-aligned (no diagonal walls)
3. Add child nodes of type `RoomConnector3D` where doors/connections should exist
4. For each `RoomConnector3D`:
   - Position it at the doorway location
   - Rotate it so the +Z (blue arrow) points OUTWARD from the room
   - Set `connection_type` to a tag like `"standard_door"` or `"large_gate"`
5. Save the scene (e.g., `rooms/entrance_room.tscn`)
6. Repeat for boss room, corridor variants, junction rooms, and dead-end rooms

---

## Configuring the Generator

1. Create a new `DungeonConfig` resource: right-click in FileSystem dock → New Resource → DungeonConfig
2. Name it `test_dungeon_config.tres`, save it
3. Double-click to open in the inspector. Configure:
   - `main_path_length`: `4`
   - `branch_count`: `2`
   - `branch_depth_min`: `1`
   - `branch_depth_max`: `2`
   - `room_count_min`: `4`
   - `room_count_max`: `20`
   - `random_seed`: `12345` (for reproducible test)
   - `max_generation_attempts`: `10`
4. Assign rooms to pools:
   - Drag your entrance scene into `entrance_pool` (set `spawn_weight = 1.0`, `category = ENTRANCE`)
   - Drag your boss scene into `boss_pool` (set `spawn_weight = 1.0`, `category = BOSS`)
   - Drag corridor scenes into `corridor_pool` (set appropriate weights)
   - Drag junction scenes into `junction_pool`
   - Drag dead-end scenes into `dead_end_pool`
5. Save the config (`Ctrl+S`)

---

## Running Generation (Demo Scene)

1. Open `demo/demo_dungeon.tscn`
2. Select the `DungeonGenerator3D` node in the scene tree
3. In the Inspector, assign the `DungeonConfig` resource to the `config` property (drag from FileSystem)
4. Click the `[Generate]` button in the inspector
5. Expected: the editor viewport shows connected rooms appearing as children of the generator node

---

## Validation Checklist

Run through these scenarios to verify the feature:

### VS-001: Basic Generation
- **Setup**: Entrance (1 connector), corridor (2 connectors), boss (1 connector) in pools
- **Config**: main_path_length=3, branch_count=0
- **Action**: Click Generate
- **Expected**: 3 rooms visible, no overlaps, entrance door connects to corridor, corridor connects to boss. Console shows no errors.

### VS-002: Connector Type Mismatch
- **Setup**: Entrance has connector `"door_A"`, boss has connector `"door_B"`
- **Config**: main_path_length=2, branch_count=0
- **Action**: Click Generate
- **Expected**: Generation fails. Console/log shows `generation_failed("No matching connectors found")`.

### VS-003: Branch Generation
- **Setup**: Full pool with all 5 categories
- **Config**: main_path_length=5, branch_count=3, branch_depth_min=1, branch_depth_max=2
- **Action**: Click Generate
- **Expected**: Main path has 5 rooms; 3 branches emanate from main-path rooms; each branch has 1-2 rooms ending in dead-end rooms.

### VS-004: Clear and Regenerate
- **Setup**: After VS-003, a dungeon is visible
- **Action**: Click Clear → verify all generated rooms disappear → modify seed → click Generate
- **Expected**: New dungeon with different layout appears. Repeat 5 times — each layout differs.

### VS-005: Reproducibility
- **Setup**: Config with seed=42
- **Action**: Generate → note layout → Clear → Generate again
- **Expected**: Same layout produced both times (same rooms, same positions, same connections).

### VS-006: Performance (30 rooms)
- **Setup**: Pool with 50 corridor rooms, seed=0 (random)
- **Config**: main_path_length=10, branch_count=10, branch_depth_max=2, room_count_max=30
- **Action**: Click Generate
- **Expected**: Generation completes in under 5 seconds. No editor freeze.

### VS-007: Missing Resource
- **Setup**: A RoomData entry with a broken PackedScene path (delete the .tscn file after assigning)
- **Action**: Click Generate
- **Expected**: Generation fails with message `"Missing PackedScene reference: <path>"` before any rooms are placed.

### VS-008: Empty Pool
- **Setup**: DungeonConfig with all pools empty
- **Action**: Click Generate
- **Expected**: Immediate failure with `"Empty room pool"`.

---

## Expected Console Output

**Success**:
```
[generation_completed] 18 rooms placed, 17 connections, main path valid
```

**Failure**:
```
[generation_failed] Cannot satisfy main path length: need 5 rooms but pool has only 3 unique scenes
```

---

## Next Steps

After validating the above scenarios:
1. Connect a NavMesh baker node to the `generation_completed` signal
2. Place a player character at the entrance room's position
3. Press F5 to test runtime navigation through the generated dungeon
