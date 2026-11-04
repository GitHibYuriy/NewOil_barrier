# NewOil_barrier

**Radial–vertical multiphase reservoir simulation with aquifer support and local permeability barriers**

Research software written for GNU Octave and the MATLAB Reservoir Simulation Toolbox (MRST). This repository preserves the tested NewOil_v31 source code as a baseline for subsequent studies of permeability-barrier effects on water coning.

## Scope

- Radial–vertical reservoir grid and two-zone rock-property inputs.
- Multiphase flow and production controls.
- Optional Fetkovich aquifer support.
- Optional local permeability barrier controlled through `Input/NewOil_Grid_Input.m`.
- Independent SPE CSP-2 coning benchmark in `CSP2_Engine/`.
- A retained μ=4 reference case in `MU4_Engine/`.

## Dependencies

Install a compatible version of **GNU Octave** and **MRST**, including the modules `ad-core`, `ad-props`, `ad-blackoil`, and `deckformat`. MRST is a separate dependency and is **not distributed** with this repository. The source includes local compatibility helpers (`deval.m`, `griddedInterpolant.m`). Exact versions of Octave/MRST used for the verified runs should be recorded before final release.

## Running

First initialize MRST in Octave using your local MRST startup path, then run from the repository root:

```matlab
run('/path/to/mrst/startup.m');
cd('/path/to/NewOil_barrier');
addpath(pwd);
addpath(genpath(fullfile(pwd, 'Modules')));
NewOil_CheckInputs  % static validation, no reservoir simulation
NewOil_Main         % full main simulation
```

To run the independent SPE CSP-2 benchmark:

```matlab
Run_CSP2
```

Adjust the input parameters in `Input/`. The primary grid and barrier controls are in `Input/NewOil_Grid_Input.m`. The current rock-property input uses **two vertical zones** separated by `LOWER_LAYER_FIRST`; `UPPER` and `LOWER` in variable names identify these zones, **not numerical bounds**. Individual rock properties per cell or per K-layer are not yet exposed as general input arrays.

## Verification status

The following figures are from prior runs reported by the project developer; **they have not been independently rerun in this publication-preparation environment**.

| Case | Time | Key results |
| --- | --- | --- |
| μ=4 reference | 7305 days | Qo 1.997389, Qw 98.002611 m³/day; WCUT 0.980026; BHP 136.036530 bar |
| SPE CSP-2 | 900 days | Qo 15.8987, Qw 10.2383, Qg 3779.238; WCUT 0.3917; BHP 23152.47 kPa |

A shorter μ=4 rerun through day 366 and the SPE CSP-2 900-day run were reported as checks after the removal of the main-case `EclipseShablon.DATA` dependency. See the benchmark source inputs and scripts for reproducibility. Do not interpret the figures as a validation of the physical effects of permeability barriers: that research is planned for a later stage.

## Repository layout

- `Input/` — main case physical properties, schedule and controls.
- `Modules/` — main case calculation modules.
- `CSP2_Engine/` — separate SPE CSP-2 benchmark implementation.
- `MU4_Engine/` — retained earlier μ=4 reference implementation (not the primary current code path).
- `NewOil_Main.m` — main entry point.
- `NewOil_CheckInputs.m` — static input checks.
- `Run_CSP2.m` — benchmark entry point.

## Publication and citation

A stable GitHub release tag is recommended for article citations. This repository is attributed to Yuriy Zarubin and is prepared for release under the MIT License. Cite the tagged version using `CITATION.cff`; optionally archive the release with Zenodo for a DOI.

**License:** MIT for original code authored by Yuriy Zarubin. Third-party benchmark files and materials must be reviewed for redistribution rights before public release.
