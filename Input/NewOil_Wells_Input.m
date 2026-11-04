% ========================================================================
% NewOil_Wells_Input.m
% PURPOSE: Central producing well, perforated layers, and completion well indices.
%
% MODEL AND DEPENDENCIES:
%   The radial model currently contains one producer. WELL_PERF_K lists the
%   perforated K layers in the model indexing convention. WELL_WI_MDM
%   supplies a common WI in mD*m. If WELL_WI_BY_PERF_MDM is nonempty, it must
%   contain exactly one WI for each element of WELL_PERF_K in the SAME ORDER.
%   The two vectors form corresponding (K, WI) pairs; non-perforated layers
%   are omitted. An empty WI vector retains the common WI. The well radius is
%   in metres; the reference depth in metres; the test BHP in bar.
%
% PARAMETERS AND UNITS:
%   WELL_NAME: Producer identifier [text]
%   WELL_TYPE: Well type, currently PRODUCER
%   WELL_PERF_K: Perforated K layers [1-based indices]
%   WELL_RADIAL_I: Radial well cell index, currently 1
%   WELL_WI_MDM: Common well index [mD*m]
%   WELL_RADIUS_M: Wellbore radius [m]
%   WELL_REF_DEPTH_M: Well pressure reference depth [m]
%   WELL_TEST_BHP_BAR: Initial construction/test BHP [bar]
%   WELL_WI_BY_PERF_MDM: Optional WI vector by perforation [mD*m]
%
% INPUT FORMAT: Octave/MATLAB scalar, string, vector, or expression assignments.
% EDITING RULE: Change values only in the active assignments below.
%             Do not change parameter names or derived formulas.
% EXAMPLE (illustration only; do not uncomment without editing active values):
%   WELL_PERF_K = [1; 3; 5; 8; 12];
%   WELL_WI_BY_PERF_MDM = [1200; 1500; 1720; 2100; 2500];
% The five entries are paired by position, not by the numerical K index.
% ========================================================================

WELL_NAME = 'Well_producer'; % well identifier
WELL_TYPE = 'PRODUCER';    % producer
WELL_PERF_K = (1:18).';    % perforated K indices
WELL_RADIAL_I = 1;              % radial cell index
WELL_WI_MDM = 1720.46; % explicit completion WI, mD*m
WELL_RADIUS_M = 0.04; % borehole radius, m (diameter = 0.08 m)
WELL_REF_DEPTH_M = 2700;  % BHP reference depth, m
WELL_TEST_BHP_BAR = 80;    % test BHP, bar
WELL_WI_BY_PERF_MDM = []; % perforation-specific WI, mD*m
