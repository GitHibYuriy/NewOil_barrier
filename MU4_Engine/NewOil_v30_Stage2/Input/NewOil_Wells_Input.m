% Well parameters (v29); currently one central well on the axisymmetric grid.
WELL_NAME = 'Well_producer';
WELL_TYPE = 'PRODUCER';
WELL_PERF_K = (1:18).';
WELL_RADIAL_I = 1;
WELL_WI_MDM = 1720.46; % explicit completion WI, mD*m
WELL_RADIUS_M = 0.04; % borehole radius, m (diameter = 0.08 m)
WELL_REF_DEPTH_M = 2700;
WELL_TEST_BHP_BAR = 80;

% Optional: one WI [mD*m] for each completion, in WELL_PERF_K order.
% Empty preserves validated v29 common WI.
WELL_WI_BY_PERF_MDM = [];
