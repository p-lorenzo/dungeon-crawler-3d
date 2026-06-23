# Research: Random Connector Selection

This document captures the research and design decisions for implementing random connector selection in the `DungeonBuilder` class.

## Decision 1: Connector Selection Randomization

### Selected Option
Collect all unused connector indices for the current room into an array, and pick one at random using the builder's `_rng` (RandomNumberGenerator) instance.

### Rationale
- **Preserves Reproducibility**: Using the existing `_rng` instance ensures that the layouts remain completely reproducible when using the same seed configuration, satisfying Core Principle V (Resource-Driven Configuration) and the spec requirement.
- **Labyrinth Topology**: Picking a random exit connector instead of the first one in the list naturally forces branches to curve and turn, creating winding labyrinth structures.
- **No Overlap Risk**: The AABB manager will still validate that the placed room doesn't overlap existing geometry. If the selected random connector leads to an overlap, standard backtracking handles reverting the placement and trying other branches.

### Alternatives Considered
- **Uniform random shuffle**: Shuffling the list of candidate rooms. This is already done for room prefabs, but doesn't solve the problem where a room itself always extends out of the same front exit door first. We must randomize which exit port on the parent room is selected for extension.
- **Global `randi()`**: Using global random functions. This was rejected because it breaks seed reproducibility and is not isolated to the custom generator configurations.

---

## Decision 2: Implementation within `_find_unused_connector`

### Selected Option
Update `DungeonBuilder._find_unused_connector(placement, room_index) -> int` to return a randomly chosen unused connector index from the set of all unused connectors, rather than returning the first one found.

### Rationale
- **Low Impact / High Yield**: Reusing this helper function means no changes are needed in the core generation recursion logic (`_build_main_path`, `_build_branches`). The recursion loop simply asks for an unused connector, and receives a random one.
- **Safety**: Returning `-1` when the list is empty remains untouched, which maintains compatibility with the deadlock and branch termination checks.
