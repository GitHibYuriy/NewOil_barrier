% ========================================================================
% NewOil_Controls_Input.m
% PURPOSE: Legacy well operating controls, production limits, restart, and aquifer coupling.
%
% MODEL AND DEPENDENCIES:
%   This file is evaluated after the calendar and numerics inputs. In legacy
%   mode the requested well target is defined by OPERATE and OPERATE_VALUE.
%   LRAT is surface liquid rate in m3/day; BHP is pressure in bar. The
%   optional rate ramp raises LRAT from its starting value. Threshold actions
%   STOP or WARNING control water-cut and GOR handling. Aquifer coupling
%   settings govern the iterative/implicit solution. When
%   WELL_SCHEDULE_ENABLED is true, the CSV schedule can override legacy well
%   controls. DTMAX_DAYS is defined only in NewOil_Numerics_Input.m.
%
% PARAMETERS AND UNITS:
%   SIMULATION_DAYS: Derived simulation horizon [days]
%   TIMESTEP_DAYS: Compatibility metadata [days]
%   OPERATE: Operating mode: LRAT or BHP
%   OPERATE_VALUE: Liquid rate [m3/day] or BHP [bar]
%   LIMIT_BHP_MIN: Minimum producing BHP [bar]
%   LIMIT_LRAT_MAX: Maximum liquid production [m3/day]
%   RAMP_LRAT_ENABLED: Enable liquid-rate ramp [logical]
%   RAMP_LRAT_START: Initial liquid rate [m3/day]
%   RAMP_LRAT_STEP: Rate increment [m3/day]
%   RAMP_LRAT_EVERY_DAYS: Time between increments [days]
%   ENABLE_BHP_SWITCH: Enable switch to pressure control [logical]
%   RETURN_TO_LRAT: Attempt return to liquid-rate control [logical]
%   RETURN_MARGIN_BAR: Return hysteresis [bar]
%   RETURN_CHECK_DAYS: Minimum interval between return tests [days]
%   CONTROL_WCUT_MAX: Water-cut threshold [fraction]
%   ACTION_WCUT: Water-cut action: STOP or WARNING
%   CONTROL_GOR_MAX: Gas/oil ratio limit [Sm3/Sm3], Inf disables
%   ACTION_GOR: GOR action: STOP or WARNING
%   RESTART: Resume from saved checkpoint [logical]
%   AQUIFER_COUPLING: Aquifer coupling algorithm [text]
%   AQ_ITER_MAX: Maximum aquifer iterations [integer]
%   AQ_ITER_RTOL: Relative aquifer flux tolerance [-]
%   AQ_ITER_ATOL_M3D: Absolute aquifer flux tolerance [m3/day]
%   AQ_ITER_RELAX: Fixed-point relaxation factor [-]
%
% INPUT FORMAT: Octave/MATLAB scalar, string, vector, or expression assignments.
% EDITING RULE: Change values only in the active assignments below.
%             Do not change parameter names or derived formulas.
% CONSTRAINTS: rate and BHP targets > 0; WCUT threshold in (0,1];
% AQ_ITER_MAX > 0; AQ_ITER_RELAX in (0,1]; GOR=Inf disables GOR stop.
% ========================================================================

fprintf('Calendar-aware adaptive step, DTMAX = %.3f days\n', DTMAX_DAYS);
SIMULATION_DAYS = (STOP_SERIAL-START_SERIAL); % effective STOP horizon
TIMESTEP_DAYS = DTMAX_DAYS;      % compatibility metadata only
OPERATE = 'LRAT';                % 'LRAT' or 'BHP'
OPERATE_VALUE = 100;            % Final LRAT target, m3/day; BHP: bar
LIMIT_BHP_MIN = 120;             % Minimum BHP while on LRAT, bar
LIMIT_LRAT_MAX = 100;           % Must be >= final LRAT target, m3/day
RAMP_LRAT_ENABLED = true;         % 20, 40, 60, 80, 100 m3/day
RAMP_LRAT_START = 20;            % Initial LRAT, m3/day
RAMP_LRAT_STEP = 20;             % Increase, m3/day
RAMP_LRAT_EVERY_DAYS = 1;       % Increase every N days
ENABLE_BHP_SWITCH = false;        % Preserve v26 behavior; enable after validation
RETURN_TO_LRAT = false;           % Try returning from BHP to LRAT
RETURN_MARGIN_BAR = 10;         % Hysteresis: trial BHP >= MIN + margin
RETURN_CHECK_DAYS = 5;           % At most one return attempt every N days
CONTROL_WCUT_MAX = 0.98;         % 0..1
ACTION_WCUT = 'STOP';            % 'STOP' or 'WARNING'
CONTROL_GOR_MAX = Inf;           % Surface gas/oil ratio; Inf disables
ACTION_GOR = 'STOP';             % 'STOP' or 'WARNING'
RESTART = false ;                 % true = resume saved checkpoint
AQUIFER_COUPLING = 'FULLY_IMPLICIT';  % pressure-dependent AD source
AQ_ITER_MAX = 12;                 % maximum MRST solves per trial timestep
AQ_ITER_RTOL = 1e-4;              % relative influx-rate tolerance
AQ_ITER_ATOL_M3D = 0.001;        % absolute influx-rate tolerance (m3/day)
AQ_ITER_RELAX = 0.5;             % damped fixed point, (0,1]
