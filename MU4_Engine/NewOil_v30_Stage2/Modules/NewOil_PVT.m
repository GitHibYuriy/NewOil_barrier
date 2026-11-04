% =========================================================================
% STAGE 6: Create real MRST black-oil fluid/model from the Eclipse deck
% =========================================================================
fprintf('\n=== Stage 6: Real MRST Black-Oil model ===\n');

assert(exist('fluidInput','var')==1, 'Run NewOil_PVT_Tables.m first');
templateFile = fullfile(inputDir, 'EclipseShablon.DATA');
gridData = struct('rw',rw,'dr',dr,'dz',dz,'dtop',dtop, ...
 'lowerLayerFirst',LOWER_LAYER_FIRST,'poroUpper',PORO_UPPER,'poroLower',PORO_LOWER, ...
 'krUpper',KR_UPPER_MD,'krLower',KR_LOWER_MD, ...
 'kzUpper',KZ_UPPER_MD,'kzLower',KZ_LOWER_MD,'kvMultiplier',KV_MULTIPLIER, ...
 'barrierEnabled',BARRIER_ENABLED,'barrierI',BARRIER_I,'barrierK',BARRIER_K, ...
 'barrierKr',BARRIER_KI_MD,'barrierKz',BARRIER_KK_MD);
deckFile = fullfile(resultDir, 'NewOil_Internal_MRST_Deck.DATA');
NewOil_BuildDeckFrom6col(fluidInput, templateFile, deckFile, gridData);
assert(exist(deckFile, 'file') == 2, ...
       ['Deck not found: ', deckFile]);

% The Eclipse/OPM deck is used here ONLY as a source of fluid/PVT/relperm
% definitions. Its RADIAL grid is NOT used by MRST.
deckFluid = readEclipseDeck(deckFile);
deckFluid = convertDeckUnits(deckFluid);

% Force one fluid/saturation region for our custom radial grid.
fluid = initDeckADIFluid(deckFluid, 'G', Gax, ...
                        'region_method', 'override', ...
                        'regionOverride', struct('PVTNUM', ':', ...
                                                 'SATNUM', ':', ...
                                                 'ROCKNUM', ':', ...
                                                 'IMBNUM', ':', ...
                                                 'SURFNUM', ':'));

fprintf('initDeckADIFluid completed from NewOil_Fluid_PVT.DATA.\n');
muCheck = fluid.muO(15347.2*1000,83.5271,false)/centi/poise;
fprintf('PVT CHECK muO(Pb) = %.6f cP\n',muCheck);
assert(abs(muCheck-fluidInput.PVT6(end,5))<1e-3, 'PVT viscosity mismatch');

% Create the actual three-phase black-oil model.
% Dissolved gas in oil is enabled; vaporized oil in gas is disabled.
model = NewOil_FetkovichModel(Gax, rock, fluid, ...
                             'water', true, ...
                             'oil', true, ...
                             'gas', true, ...
                             'disgas', true, ...
                             'vapoil', false);

% Replace standard planar TPFA operators by our already validated exact
% axisymmetric operators.
model.operators = opExact;

fprintf('GenericBlackOilModel created.\n');
fprintf('Water active : %d\n', model.water);
fprintf('Oil active   : %d\n', model.oil);
fprintf('Gas active   : %d\n', model.gas);
fprintf('Dissolved gas (disgas): %d\n', model.disgas);
fprintf('Vaporized oil (vapoil): %d\n', model.vapoil);

% Validate that the model retained the exact operators.
assert(numel(model.operators.T) == numel(Tint));
dTmodel = max(abs(model.operators.T - Tint));
fprintf('Max |T_model-T_exact|          : %.12e\n', dTmodel);
fprintf('Model pore volume total        : %.12e m^3\n', sum(model.operators.pv));
assert(dTmodel < 1e-20);

% Basic checks that the Eclipse PVT/relative-permeability functions exist.
% Eclipse three-phase oil relperm is split into oil-water and oil-gas
% functions in MRST: krOW and krOG (there is no single fluid.krO field).
neededFluidFields = {'bW','muW','bO','muO','bG','muG', ...
                     'rsSat','krW','krOW','krG','krOG'};
for ii = 1:numel(neededFluidFields)
    nm = neededFluidFields{ii};
    assert(isfield(fluid, nm), ['Missing fluid field: ', nm]);
end
fprintf('Basic PVT/relperm function handles found (krOW + krOG).\n');

fprintf('Stage 6 Black-Oil model created successfully.\n');


% =========================================================================
% OCTAVE COMPATIBILITY
% =========================================================================
% MRST 2026a uses MATLAB's griddedInterpolant and deval during EQUIL
% initialization. GNU Octave 11.1 does not implement them. Add compatible wrappers.
compatDir = fileparts(mfilename('fullpath'));
if isempty(compatDir)
    compatDir = pwd;
end
addpath(compatDir);

