% NewOil_Grid_Input.m - editable grid and rock properties (baseline v28)
% Units: m, mD, dimensionless porosity.
% Nr follows dr; original CMG DTOP is interpolated by physical radius.
rw = 0.076;
dr = [0.08 0.42 0.5 1 repmat(2,1,14) repmat(10,1,37)];

dz = [ones(1,30), 0.1, 1.0];

% CMG DTOP: top of first layer for each radial column, m.
dtop = [2637.56 2637.57 2637.59 2637.62 2637.71 2637.82 2637.93 2638.06 2638.79 ...
        2639.64 2640.58 2641.60 2642.68 2643.82 2645.01 2646.24 2647.51 2648.83 ...
        2650.17 2651.56 2652.97 2654.42 2655.90 2657.40 2658.93 2660.49 2662.07 ...
        2663.67 2665.30 2666.95 2668.62 2670.31 2672.03 2673.76 2675.51 2677.28 ...
        2679.07 2680.88 2682.71 2684.55 2686.41 2688.29 2690.18 2692.09 2694.01 ...
        2695.95 2697.90];

% Original CMG radial grid (47 cells)
dr_original = [0.08 0.42 0.5 1 repmat(2,1,4) repmat(10,1,39)];

% Original radial cell centers
rEdge_original = [rw, rw + cumsum(dr_original)];
rCenter_original = 0.5*(rEdge_original(1:end-1) + rEdge_original(2:end));

% Current radial cell centers
rEdge_new = [rw, rw + cumsum(dr)];
rCenter_new = 0.5*(rEdge_new(1:end-1) + rEdge_new(2:end));

% Interpolate original DTOP onto the new radial grid
assert(numel(dtop) == numel(dr_original), 'Original DTOP count mismatch');

dtop = interp1(rCenter_original, dtop, rCenter_new, 'linear', 'extrap');



% Layer ranges (inclusive); baseline: 1:30 and 31:32.
PORO_UPPER = 0.18;
PORO_LOWER = 0.20;
KR_UPPER_MD = 40;
KR_LOWER_MD = 40;
KZ_UPPER_MD = 40;
KZ_LOWER_MD = 100;
LOWER_LAYER_FIRST = 31;
KV_MULTIPLIER = 1.0;  % 1.0 = validated v28 baseline

% ===== Optional permeability barrier (CMG I/J/K indexing) =====
% I: radial cells 1..Nr; J: single axisymmetric row (always 1);
% K: vertical layers 1..32. Bounds are inclusive.
% Example below targets 10 cells in layer 31.


BARRIER_ENABLED = false;  % false preserves validated v28 baseline
BARRIER_I = [1 10];
BARRIER_J = [1 1];
BARRIER_K = [31 31];
% Directional absolute permeability inside barrier, mD.
% KI is radial; KJ is circumferential (not used by 2D axisymmetric solver);
% KK is vertical. Zero KK blocks vertical flux across barrier cells.
BARRIER_KI_MD = 40;
BARRIER_KJ_MD = 40;
BARRIER_KK_MD = 0;
