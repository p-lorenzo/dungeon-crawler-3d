# Quickstart Validation Guide: Random Connector Selection

This guide defines the procedures to verify that the Random Connector Selection feature works correctly and is fully reproducible.

## Prerequisites
- Godot 4.6 installed.
- Access to the headless Godot executable.

## Running the Programmatic Verification Test
A test script `demo/test_random_connector_selection.gd` will verify that the generator produces winding paths and that the output is reproducible.

Run the test suite headlessly from the repository root:
```bash
godot --headless -s demo/test_random_connector_selection.gd
```

### Verification Scenarios

- **Scenario 1: Layout Winding and Randomization**
  - **Prerequisites**: Demo room scenes with multiple exits are available.
  - **Execution**: Run generation.
  - **Expected Outcome**: The generated layout contains turns and twists. Placements' world transforms show Y-rotations other than a single straight heading.

- **Scenario 2: Seed Reproducibility**
  - **Execution**: Generate twice with the exact same seed (e.g. `12345`).
  - **Expected Outcome**: Both generated layouts have the identical placement count, room types, and transforms.

- **Scenario 3: Seed Variability**
  - **Execution**: Generate two layouts using two different seeds (e.g. `12345` vs `67890`).
  - **Expected Outcome**: The layouts differ in room placement, count, or path directions, proving that changing the seed changes the randomization of the connector selection.
