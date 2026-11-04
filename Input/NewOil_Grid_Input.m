% ========================================================================
% NewOil_Grid_Input.m
% PURPOSE: Radial-vertical geometry, rock properties, and optional local permeability barrier.
%
% MODEL AND DEPENDENCIES:
%   The model has one circumferential row (J=1). I is radial, K is vertical.
%   Cell widths and depths are in metres; permeability is in mD. dr and dz
%   define the grid dimensions. The original CMG dtop values are interpolated
%   to the current radial grid; preserve their order. Rock groups split at
%   LOWER_LAYER_FIRST. The barrier ranges are inclusive; disabling the
%   barrier preserves the reference case.
%
% PARAMETERS AND UNITS:
%   rw: Inner radius [m]
%   dr: Radial cell widths [m], determines Nr
%   dz: Layer thicknesses [m], determines Nz
%   dtop: Original top depth of each radial column [m], later interpolated
%   dr_original: Original CMG radial widths [m] corresponding to dtop
%   rEdge_original: Derived original radial boundaries [m]
%   rCenter_original: Derived original radial centres [m]
%   rEdge_new: Derived current radial boundaries [m]
%   rCenter_new: Derived current radial centres [m]
%   PORO_UPPER: Upper-zone porosity [fraction]
%   PORO_LOWER: Lower-zone porosity [fraction]
%   KR_UPPER_MD: Upper-zone radial permeability [mD]
%   KR_LOWER_MD: Lower-zone radial permeability [mD]
%   KZ_UPPER_MD: Upper-zone vertical permeability [mD]
%   KZ_LOWER_MD: Lower-zone vertical permeability [mD]
%   LOWER_LAYER_FIRST: First K layer of lower zone [1-based]
%   KV_MULTIPLIER: Multiplier of vertical permeability [-]
%   BARRIER_ENABLED: Apply local permeability barrier [logical]
%   BARRIER_I: Inclusive radial I range [first last]
%   BARRIER_J: Inclusive circumferential J range [1 1]
%   BARRIER_K: Inclusive vertical K range [first last]
%   BARRIER_KI_MD: Barrier radial permeability [mD]
%   BARRIER_KJ_MD: Barrier circumferential permeability [mD]
%   BARRIER_KK_MD: Barrier vertical permeability [mD]
%
% INPUT FORMAT: Octave/MATLAB scalar, string, vector, or expression assignments.
% EDITING RULE: Change values only in the active assignments below.
%             Do not change parameter names or derived formulas.
% CONSTRAINTS: dr and dz > 0; 0 < porosity <= 1; permeability >= 0.
% BARRIER_I/J/K must refer to existing cells; J=1 in this model.
% ========================================================================

rw = 0.076;                            % inner radius, m
dr = [0.08 0.42 0.5 1 repmat(2,1,14) repmat(10,1,37)]; % radial cell widths, m
dz = [ones(1,30), 0.1, 1.0]; % layer thicknesses, m
dtop = [2637.56 2637.57 2637.59 2637.62 2637.71 2637.82 2637.93 2638.06 2638.79 ...
        2639.64 2640.58 2641.60 2642.68 2643.82 2645.01 2646.24 2647.51 2648.83 ...
        2650.17 2651.56 2652.97 2654.42 2655.90 2657.40 2658.93 2660.49 2662.07 ...
        2663.67 2665.30 2666.95 2668.62 2670.31 2672.03 2673.76 2675.51 2677.28 ...
        2679.07 2680.88 2682.71 2684.55 2686.41 2688.29 2690.18 2692.09 2694.01 ...
        2695.95 2697.90];
dr_original = [0.08 0.42 0.5 1 repmat(2,1,4) repmat(10,1,39)]; % original CMG widths, m
rEdge_original = [rw, rw + cumsum(dr_original)]; % derived boundaries, m
rCenter_original = 0.5*(rEdge_original(1:end-1) + rEdge_original(2:end)); % derived centres, m
rEdge_new = [rw, rw + cumsum(dr)]; % derived boundaries, m
rCenter_new = 0.5*(rEdge_new(1:end-1) + rEdge_new(2:end)); % derived centres, m
assert(numel(dtop) == numel(dr_original), 'Original DTOP count mismatch');
dtop = interp1(rCenter_original, dtop, rCenter_new, 'linear', 'extrap'); % top depths, m
PORO_UPPER = 0.18;              % upper porosity, fraction
PORO_LOWER = 0.20;              % lower porosity, fraction
KR_UPPER_MD = 40;                % upper radial k, mD
KR_LOWER_MD = 40;                % lower radial k, mD
KZ_UPPER_MD = 40;                % upper vertical k, mD
KZ_LOWER_MD = 100;              % lower vertical k, mD
LOWER_LAYER_FIRST = 31;    % first lower K layer
KV_MULTIPLIER = 1.0;  % 1.0 = validated v28 baseline
BARRIER_ENABLED = false;  % false preserves validated v28 baseline
BARRIER_I = [1 10];            % radial index range
BARRIER_J = [1 1];              % circumferential index range
BARRIER_K = [31 31];          % vertical index range
BARRIER_KI_MD = 40;            % barrier radial k, mD
BARRIER_KJ_MD = 40;            % barrier circumferential k, mD
BARRIER_KK_MD = 0;              % barrier vertical k, mD
