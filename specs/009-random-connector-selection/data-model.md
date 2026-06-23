# Data Model: Random Connector Selection

This feature does not introduce any new data models or resources. It utilizes the existing configuration formats and spatial topologies.

## 1. DungeonConfig (Existing Godot Resource)
The `random_seed` property of `DungeonConfig` is used to seed the `RandomNumberGenerator` inside the `DungeonBuilder`.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `random_seed` | `int` | `0` | Seed used to configure the generator. If `0`, a random seed is selected. |

## 2. In-Memory Traversal State
During `DungeonBuilder` execution, the `_rng` variable of type `RandomNumberGenerator` is configured with the `random_seed` from `DungeonConfig`.

In `_find_unused_connector()`, we calculate:
1. `used_indices: Array[int]` — Indices of connector transforms matched in existing edges.
2. `unused_indices: Array[int]` — All connectors whose index is not in `used_indices` and whose connection type is not empty.
3. Selection of connector index: `var rand_idx: int = _rng.randi() % unused_indices.size()`
4. Returns `unused_indices[rand_idx]` to determine the path extension port.
