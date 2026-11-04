% User controls; loaded after NewOil_Calendar.m.
% DTMAX_DAYS is set exclusively by NewOil_Numerics_Input.m
fprintf('EXPERIMENT v28: calendar-aware adaptive step, DTMAX = %.3f days\n', DTMAX_DAYS);
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
% The controller maintains the requested LRAT when feasible and otherwise
% maintains BHP_MIN. Set LIMIT_LRAT_MAX >= requested LRAT.
ENABLE_BHP_SWITCH = false;        % Preserve v26 behavior; enable after validation
RETURN_TO_LRAT = false;           % Try returning from BHP to LRAT
RETURN_MARGIN_BAR = 10;         % Hysteresis: trial BHP >= MIN + margin
RETURN_CHECK_DAYS = 5;           % At most one return attempt every N days
CONTROL_WCUT_MAX = 0.98;         % 0..1
ACTION_WCUT = 'STOP';            % 'STOP' or 'WARNING'
CONTROL_GOR_MAX = Inf;           % Surface gas/oil ratio; Inf disables
ACTION_GOR = 'STOP';             % 'STOP' or 'WARNING'
RESTART = false ;                 % true = resume saved checkpoint
% AQUFER COUPLING: EXPLICIT reproduces v27; ITERATIVE couples end pressure.
AQUIFER_COUPLING = 'FULLY_IMPLICIT';  % pressure-dependent AD source
AQ_ITER_MAX = 12;                 % maximum MRST solves per trial timestep
AQ_ITER_RTOL = 1e-4;              % relative influx-rate tolerance
AQ_ITER_ATOL_M3D = 0.001;        % absolute influx-rate tolerance (m3/day)
AQ_ITER_RELAX = 0.5;             % damped fixed point, (0,1]

% RESULTS_DIR selected once by NewOil_Main.m before Stage 4.
