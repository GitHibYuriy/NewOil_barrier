% ========================================================================
% NewOil_Aquifer_Input.m
% PURPOSE: Fetkovich aquifer physical properties and enable switch.
%
% MODEL AND DEPENDENCIES:
%   The aquifer represents pressure support from an external water-bearing
%   region. Keep all physical parameters consistent with the reservoir
%   geometry. AQ_RATIO is the outer/inner radius ratio. Compressibility is
%   specified in inverse pascals, not inverse kilopascals.
%
% PARAMETERS AND UNITS:
%   ENABLE_AQUIFER: Enable aquifer [logical]
%   AQ_RATIO: Outer/inner aquifer radius ratio [-], >1
%   AQ_ANGLE: Angular scaling factor [-]
%   AQ_THICKNESS_M: Aquifer thickness [m]
%   AQ_POROSITY: Aquifer porosity [fraction], 0..1
%   AQ_PERMEABILITY_MD: Aquifer permeability [mD]
%   AQ_VISCOSITY_CP: Water viscosity [cP = mPa*s]
%   AQ_COMPRESSIBILITY_PER_PA: Total compressibility [1/Pa]
%
% INPUT FORMAT: Octave/MATLAB scalar, string, vector, or expression assignments.
% EDITING RULE: Change values only in the active assignments below.
%             Do not change parameter names or derived formulas.
% CONSTRAINTS: AQ_RATIO > 1; 0 < AQ_POROSITY <= 1;
% thickness, permeability, viscosity, compressibility > 0.
% ========================================================================

ENABLE_AQUIFER = true;      % enable aquifer
AQ_RATIO = 5.0;                    % outer/inner aquifer radius ratio
AQ_ANGLE = 1.0;                    % angular scaling factor
AQ_THICKNESS_M = 31.1;      % aquifer thickness
AQ_POROSITY = 0.2;              % aquifer porosity
AQ_PERMEABILITY_MD = 100; % aquifer permeability
AQ_VISCOSITY_CP = 1.0;      % water viscosity
AQ_COMPRESSIBILITY_PER_PA = 1.0e-9; % total compressibility
assert(AQ_RATIO>1 && AQ_THICKNESS_M>0 && AQ_POROSITY>0 && AQ_POROSITY<=1);
assert(AQ_PERMEABILITY_MD>0 && AQ_VISCOSITY_CP>0 && AQ_COMPRESSIBILITY_PER_PA>0);
