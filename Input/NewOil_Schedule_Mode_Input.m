% ========================================================================
% NewOil_Schedule_Mode_Input.m
% PURPOSE: Select between legacy well controls and the external well schedule.
%
% MODEL AND DEPENDENCIES:
%   Set false to use the validated mu=4 legacy controller from
%   NewOil_Controls_Input.m. Set true to read Input/WellSchedule.csv, which
%   specifies time-dependent well modes and targets. Switching modes changes
%   the model controls and is not a documentation-only edit.
%
% PARAMETERS AND UNITS:
%   WELL_SCHEDULE_ENABLED: false: legacy controls; true: WellSchedule.csv
%
% INPUT FORMAT: Octave/MATLAB scalar, string, vector, or expression assignments.
% EDITING RULE: Change values only in the active assignments below.
%             Do not change parameter names or derived formulas.
% ========================================================================

WELL_SCHEDULE_ENABLED = false; % false: legacy controls; true: wellschedule.csv
