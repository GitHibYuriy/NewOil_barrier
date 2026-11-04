% ========================================================================
% NewOil_Numerics_Input.m
% PURPOSE: Adaptive timestep configuration and simulation calendar start.
%
% MODEL AND DEPENDENCIES:
%   All timestep limits are in days. The actual simulation stop date is read
%   from NewOil_ReportCalendar.csv. The adaptive controller grows or cuts
%   steps subject to numerical convergence and water-cut limits. Keep
%   DTMAX_DAYS defined only here; controls use it as compatibility metadata.
%
% PARAMETERS AND UNITS:
%   DTINIT_DAYS: Initial trial timestep [days]
%   DTMIN_DAYS: Minimum permitted timestep [days]
%   DTMAX_DAYS: Maximum permitted timestep [days]
%   DTGROW: Accepted-step growth multiplier [-]
%   MAX_STEP_CUTS: Maximum cuts per trial step [integer]
%   MAX_WCUT_STEP: Maximum water-cut change per step [fraction]
%   START_DATE: Simulation start [YYYY-MM-DD]
%
% INPUT FORMAT: Octave/MATLAB scalar, string, vector, or expression assignments.
% EDITING RULE: Change values only in the active assignments below.
%             Do not change parameter names or derived formulas.
% CONSTRAINTS: DTMIN_DAYS > 0; DTINIT_DAYS > 0;
% DTMAX_DAYS >= DTINIT_DAYS; DTGROW >= 1.
% ========================================================================

DTINIT_DAYS = 0.1;              % initial trial timestep
DTMIN_DAYS = 0.001;            % minimum permitted timestep
DTMAX_DAYS = 31;                  % maximum permitted timestep
DTGROW = 1.15;                      % accepted-step growth multiplier
MAX_STEP_CUTS = 12;            % maximum cuts per trial step
MAX_WCUT_STEP = 0.02;        % maximum water-cut change per step
START_DATE = '2000-01-01'; % simulation start
assert(DTINIT_DAYS>0 && DTMIN_DAYS>0 && DTMAX_DAYS>=DTINIT_DAYS);
assert(DTGROW>=1 && MAX_STEP_CUTS>=0 && MAX_WCUT_STEP>0);
