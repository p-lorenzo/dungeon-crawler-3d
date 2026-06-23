# Feature Specification: Random Connector Selection

**Feature Branch**: `009-random-connector-selection`

**Created**: 2026-06-23

**Status**: COMPLETE

**Input**: User description: "c'é un problema con l'algoritmo che sceglie dove posiziono le stanze, attualmente il main branch si crea rettilineo, viene sempre scelta la porta di fronte come apertura, questo crea un branch main dritto e anche i secondary branches sono sempre dritti. Vorrei invece che venga sempre scelta una apertura casuale per proseguire i vari branch, in questo modo il risultato finale é più simile a un labirinto"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Labyrinth-Like Dungeon Layouts (Priority: P1)

As a dungeon designer, I want the dungeon generator to pick a random unused connector when continuing a branch, so that the dungeon layout curves organicly and creates winding, labyrinth-like paths rather than straight lines.

**Why this priority**: Core requirement of the feature. Random selection is necessary to make the procedural dungeon layouts look organic and winding.

**Independent Test**:
1. Setup a test config with a fixed seed and rooms with multiple exits.
2. Trigger layout generation.
3. Verify that the generator creates layouts with turns and corners using different doors rather than sticking to the same straight door index.
4. Run the generation multiple times with the same seed and confirm the resulting layout is identical (reproducibility check).

**Acceptance Scenarios**:

1. **Given** a room has multiple unused exits (connectors), **When** the builder decides which connector to extend the path from, **Then** it selects one of the unused exits at random using the builder's random number generator (`_rng`).
2. **Given** a specific random seed, **When** generating the dungeon multiple times, **Then** the exact same random connectors are chosen, producing identical layouts.

---

### Edge Cases

- **Rooms with Single Exits (Dead Ends)**: When a room has only one exit, the random selection must naturally select that single available exit without throwing index out of bounds or division by zero errors.
- **No Unused Exits**: When all connectors of a room have already been connected (used), the selection logic must return `-1` to correctly initiate backtracking or end the branch.
- **Backtracking Rollbacks**: If a chosen random path leads to an overlap conflict and requires backtracking, the generator must revert the placement and continue its random selection search without breaking the random seed sequence or looping indefinitely.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `DungeonBuilder` MUST identify all valid unused connectors on the current parent room.
- **FR-002**: The `DungeonBuilder` MUST select the next connector to extend the path from by randomly picking one of the unused connector indices.
- **FR-003**: The random selection MUST use the builder's `_rng` (RandomNumberGenerator) instance to ensure the generated layouts respect the designer's seeded configuration.
- **FR-004**: If no unused connectors are available, the selection helper MUST return `-1` to signify that the branch cannot be extended further from this room.

### Key Entities

- **`DungeonBuilder`**: The core procedural builder responsible for determining room placements, connector matching, and spatial validation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of generated layouts containing multi-connector rooms produce winding and curved branches (incorporating turns) rather than straight corridors when space permits.
- **SC-002**: Dungeon generation remains 100% deterministic and reproducible across multiple runs using the same random seed.
- **SC-003**: Selection execution adds less than 1ms overhead to the total dungeon generation time.

## Assumptions

- **RNG Initialization**: The `DungeonBuilder`'s `_rng` is already initialized and seeded before the generation starts.
- **Connector Type Compatibility**: Randomly selected connectors must still match the compatible connector types of candidates during the matcher phase.
