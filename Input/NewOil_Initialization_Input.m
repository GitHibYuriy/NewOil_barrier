% ========================================================================
% NewOil_Initialization_Input.m
% PURPOSE: Physical initial equilibrium and rock compressibility for the internally built MRST deck.
%
% MODEL AND DEPENDENCIES:
%   The seven EQUIL fields reproduce the validated mu=4 reference
%   initialization. Depths are in metres, pressures in bar. WOC and GOC
%   denote water/oil and gas/oil contacts. The RSVD endpoints supply depths
%   only: saturated solution-gas ratio is obtained from
%   NewOil_Fluid_PVT.DATA. ROCK values specify rock compressibility in the
%   ECLIPSE METRIC convention. Diagnostic INITIAL_* values do not override
%   the equilibrium initialization. No external EclipseShablon.DATA is
%   required.
%
% PARAMETERS AND UNITS:
%   EQUIL_DATUM_DEPTH_M: EQUIL pressure datum depth [m]
%   EQUIL_DATUM_PRESSURE_BAR: Pressure at datum [bar]
%   EQUIL_WOC_DEPTH_M: Water/oil contact depth [m]
%   EQUIL_PCOW_WOC_BAR: Oil-water capillary pressure at WOC [bar]
%   EQUIL_GOC_DEPTH_M: Gas/oil contact depth [m]
%   EQUIL_PCOG_GOC_BAR: Gas-oil capillary pressure at GOC [bar]
%   EQUIL_ACCURACY: Equilibrium accuracy/control integer [-]
%   RSVD_DEPTHS_M: Depth endpoints for dissolved gas profile [m]
%   ROCK_REF_PRESSURE_BAR: Rock reference pressure [bar]
%   ROCK_COMPRESSIBILITY_PER_BAR: Rock compressibility [1/bar]
%   INITIAL_PRESSURE_KPA: Reference pressure for diagnostics [kPa]
%   INITIAL_REFERENCE_DEPTH_M: Depth of diagnostic reference pressure [m]
%   INITIAL_DATUM_DEPTH_M: Diagnostic datum depth [m]
%
% INPUT FORMAT: Octave/MATLAB scalar, string, vector, or expression assignments.
% EDITING RULE: Change values only in the active assignments below.
%             Do not change parameter names or derived formulas.
% CONSTRAINTS: retain contact depths and pressure conventions when
% comparing to the validated mu=4 case; bar and kPa are not interchangeable.
% ========================================================================

EQUIL_DATUM_DEPTH_M = 2671.56; % equil pressure datum depth
EQUIL_DATUM_PRESSURE_BAR = 283.66; % pressure at datum
EQUIL_WOC_DEPTH_M = 2671.56; % water/oil contact depth
EQUIL_PCOW_WOC_BAR = 0.0354; % oil-water capillary pressure at woc
EQUIL_GOC_DEPTH_M = 2600.0; % gas/oil contact depth
EQUIL_PCOG_GOC_BAR = 0.0; % gas-oil capillary pressure at goc
EQUIL_ACCURACY = 1;            % equilibrium accuracy/control integer
RSVD_DEPTHS_M = [2600.0; 2800.0]; % depth endpoints for dissolved gas profile
ROCK_REF_PRESSURE_BAR = 289.0; % rock reference pressure
ROCK_COMPRESSIBILITY_PER_BAR = 6.0e-5; % rock compressibility
INITIAL_PRESSURE_KPA = 28366.0; % reference pressure for diagnostics
INITIAL_REFERENCE_DEPTH_M = 2701.56; % depth of diagnostic reference pressure
INITIAL_DATUM_DEPTH_M = 2671.56; % diagnostic datum depth
