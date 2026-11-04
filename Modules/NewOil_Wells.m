%% =========================================================================
% STAGE 9: Producer definition -- exact CMG completion WI, no production run
% =========================================================================
fprintf('\n=== Stage 9: Producer definition and WI conversion ===\n');

run(fullfile(inputDir, 'NewOil_Wells_Input.m'));
assert(strcmpi(WELL_TYPE,'PRODUCER'), 'Current R-Z model supports one central producer');
assert(WELL_RADIAL_I==1, 'Only central well is supported');
WI_cmg_mDm = WELL_WI_MDM;
WI_si = WI_cmg_mDm * milli*darcy * meter;

perfK = WELL_PERF_K(:);
perfCells = WELL_RADIAL_I + (perfK - 1)*Nr;
if exist('WELL_WI_BY_PERF_MDM','var') && ~isempty(WELL_WI_BY_PERF_MDM)
    assert(numel(WELL_WI_BY_PERF_MDM)==numel(perfCells), ...
        'WELL_WI_BY_PERF_MDM must have one WI per completion');
    assert(all(isfinite(WELL_WI_BY_PERF_MDM(:))) && all(WELL_WI_BY_PERF_MDM(:)>0), ...
        'Every completion WI must be finite and positive');
    WIvec = WELL_WI_BY_PERF_MDM(:) * milli*darcy*meter;
else
    WIvec = repmat(WI_si, numel(perfCells), 1);
end

% IMPORTANT:
% addWell/getDeltaZ uses G.griddim (=2 for our R-Z tensorGrid) and therefore
% requires an Nx2 centroid array. modelEq has an auxiliary third centroid
% column only for MRST's EQUIL initializer, so it must NOT be passed to
% addWell. Construct the well on the original 2-D computational grid Gax.
%
% We give addWell a harmless local-grid reference depth of zero and then
% overwrite the stored physical BHP reference depth and completion dZ using
% the true reservoir depths. WI is supplied explicitly, so no Peaceman WI
% calculation is involved.
gravity reset on
gravity([0, 9.80665]);

W9 = [];
W9 = addWell(W9, Gax, rock, perfCells, ...
    'Name',     WELL_NAME, ...
    'Type',     'bhp', ...
    'Val',      WELL_TEST_BHP_BAR*barsa, ...
    'WI',       WIvec, ...
    'Radius',   WELL_RADIUS_M, ...
    'Sign',     -1, ...
    'refDepth', 0, ...
    'compi',    [0, 1, 0]);

% Replace local R-Z depth offsets by the true physical completion depths
% relative to the CMG BHP reference depth of 2700 m.
W9.refDepth = WELL_REF_DEPTH_M;
W9.dZ = cellDepth(perfCells) - W9.refDepth;

assert(numel(W9) == 1);
assert(numel(W9.cells) == numel(perfK));
assert(all(W9.cells(:) == perfCells(:)));
assert(max(abs(W9.WI(:) - WIvec(:))) < max(1e-30, max(abs(WIvec))*1e-12));
assert(abs(W9.refDepth - WELL_REF_DEPTH_M) < 1e-12);
assert(max(abs(W9.dZ(:) - (cellDepth(perfCells)-WELL_REF_DEPTH_M))) < 1e-10);

fprintf('Number of completions           : %d\n', numel(W9.cells));
fprintf('First / last completion cell    : %d / %d\n', W9.cells(1), W9.cells(end));
fprintf('First / last layer K            : %d / %d\n', perfK(1), perfK(end));
fprintf('WI per completion (min/max)    : %.6f / %.6f mD*m\n', min(WIvec)/(milli*darcy*meter), max(WIvec)/(milli*darcy*meter));
fprintf('MRST WI per completion          : %.12e m^3\n', W9.WI(1));
fprintf('Well radius                     : %.6f m\n', W9.r(1));
fprintf('BHP reference depth             : %.6f m\n', W9.refDepth);
fprintf('Test control                    : BHP = %.6f bar\n', W9.val/barsa);
fprintf('Well sign                       : %d (producer)\n', W9.sign);
fprintf('dZ range relative to 2700 m     : %.6f ... %.6f m\n', min(W9.dZ), max(W9.dZ));

fprintf('\nCompletion depths and WI:\n');
fprintf('  K    Cell      Depth_m        dZ_m          WI_mD_m\n');
for n = 1:numel(perfCells)
    fprintf('%3d  %6d   %11.4f   %10.4f      %10.4f\n', ...
        perfK(n), perfCells(n), cellDepth(perfCells(n)), W9.dZ(n), ...
        W9.WI(n)/(milli*darcy*meter));
end

fprintf('Stage 9 producer definition completed successfully.\n');

