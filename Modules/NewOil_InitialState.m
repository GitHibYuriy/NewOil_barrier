run(fullfile(inputDir,'NewOil_Initialization_Input.m'));
% =========================================================================
% STAGE 7: Eclipse EQUIL initialization on the true physical depths
% =========================================================================
fprintf('\n=== Stage 7: Physical-depth EQUIL initialization ===\n');

% initStateDeck/initStateBlackOilAD use model.G.cells.centroids(:,3) as depth.
% Gax is deliberately a logical orthogonal R-Z grid, so replace ONLY the
% second (vertical) coordinate in a temporary model used for initialization.
% MRST's EQUIL initializer is hard-coded to read depth from column 3.
% Keep the original 2-D R-Z coordinates in columns 1:2 and append the
% Keep the exact cylindrical flow operators, but provide the gravity head
% explicitly from the TRUE physical depths. ReservoirModel.getGravityGradient()
% uses operators.gdz directly when that field exists, so it will not try the

% ============================================================
% EQUIL INITIALIZATION
% ============================================================

% ============================================================
% STAGE 7: PHYSICAL-DEPTH EQUIL INITIALIZATION
% ============================================================

% Preserve the original 2D reservoir model
modelEq = model;

% EQUIL requires physical depth in the third coordinate
modelEq.G.cells.centroids(:,3) = cellDepth(:);

% Explicit gravity for hydrostatic equilibrium
modelEq.gravity = [0, 0, 9.80665];

% Use the existing 2D operators with physical depth differences
opEq = opExact;
opEq.gdz = opEq.Grad(cellDepth(:)) * 9.80665;

% IMPORTANT: assign operators AFTER creating modelEq
modelEq.operators = opEq;

% Diagnostics
fprintf('\n=== GRAVITY BEFORE initStateDeck ===\n');
fprintf('ModelEq gravity: '); disp(modelEq.gravity);
fprintf('gdz range: %.6f ... %.6f\n', ...
    min(modelEq.operators.gdz(:)), ...
    max(modelEq.operators.gdz(:)));

% Initialize
state0 = initStateDeck(modelEq, deckFluid);

fprintf('Pressure: %.3f ... %.3f bar\n', ...
    min(state0.pressure)/1e5, max(state0.pressure)/1e5);

fprintf('Sw: %.4f ... %.4f\n', ...
    min(state0.s(:,1)), max(state0.s(:,1)));

fprintf('So: %.4f ... %.4f\n', ...
    min(state0.s(:,2)), max(state0.s(:,2)));


modelEq.operators = opEq;
% The converted Eclipse deck already contains the translated CMG EQUIL:
% datum depth/pressure, WOC and capillary pressure, with a constant initial Rs derived from the six-column PVT.

% Diagnostic: gravity immediately before EQUIL initialization
fprintf('\n=== GRAVITY BEFORE initStateDeck ===\n');
fprintf('Grid dimensions: %d\n', size(modelEq.G.cells.centroids, 2));
fprintf('Gravity dimensions: %d\n', numel(modelEq.gravity));
fprintf('Global gravity: '); disp(gravity());
fprintf('Model gravity:  '); disp(model.gravity);
fprintf('ModelEq gravity: '); disp(modelEq.gravity);

state0 = initStateDeck(modelEq, deckFluid);

% ============================================================
% GRAVITY FOR DYNAMIC RESERVOIR SIMULATION
% ============================================================

% Physical gravity gradient based on actual cell depths
opDynamic = model.operators;
opDynamic.gdz = opExact.Grad(cellDepth(:)) * 9.80665;
% Assign gravity operator to the main reservoir model
model.operators = opDynamic;
% Keep the original 2D grid geometry
% Do not modify model.G.cells.centroids

fprintf('\n=== DYNAMIC GRAVITY CHECK ===\n');
fprintf('Dynamic gdz: %.6f ... %.6f\n', ...
    min(model.operators.gdz(:)), ...
    max(model.operators.gdz(:)));



fprintf('Initial pressure: %.3f ... %.3f bar\n', ...
    min(state0.pressure)/1e5, max(state0.pressure)/1e5);

fprintf('Initial So max: %.4f\n', max(state0.s(:,2)));

% Basic validation.
assert(all(isfinite(state0.pressure)));
assert(all(isfinite(state0.s(:))));
assert(size(state0.s,1) == Gax.cells.num);

sumS = sum(state0.s, 2);
assert(max(abs(sumS - 1)) < 1e-7);

% Identify W/O/G saturation columns from the model rather than assuming them.
phaseNames = model.getPhaseNames();
iw = find(phaseNames == 'W');
io = find(phaseNames == 'O');
ig = find(phaseNames == 'G');

sw0 = state0.s(:,iw);
so0 = state0.s(:,io);
sg0 = state0.s(:,ig);

fprintf('Pressure range                 : %.6f ... %.6f bar\n', ...
        min(state0.pressure)/barsa, max(state0.pressure)/barsa);
fprintf('Sw range                       : %.8f ... %.8f\n', min(sw0), max(sw0));
fprintf('So range                       : %.8f ... %.8f\n', min(so0), max(so0));
fprintf('Sg range                       : %.8e ... %.8e\n', min(sg0), max(sg0));
fprintf('Max |Sw+So+Sg-1|              : %.12e\n', max(abs(sumS-1)));

if isfield(state0, 'rs')
    fprintf('Rs range                       : %.8f ... %.8f\n', ...
            min(state0.rs), max(state0.rs));
end

% Report the cell whose physical center is closest to the CMG datum/WOC.
zDatum = INITIAL_DATUM_DEPTH_M;
[~, iclose] = min(abs(cellDepth(:) - zDatum));
fprintf('Closest cell to datum/WOC      : %d\n', iclose);
fprintf('Cell depth                     : %.6f m\n', cellDepth(iclose));
fprintf('Cell pressure                  : %.6f bar\n', state0.pressure(iclose)/barsa);
fprintf('Cell Sw / So / Sg              : %.8f / %.8f / %.8e\n', ...
        sw0(iclose), so0(iclose), sg0(iclose));

% No initial free-gas cap is expected for this case.
nFreeGas = sum(sg0 > 1e-8);
fprintf('Cells with Sg > 1e-8           : %d\n', nFreeGas);

fprintf('Stage 7 EQUIL initialization completed successfully.\n');

