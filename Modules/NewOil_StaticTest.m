%% =========================================================================
% STAGE 8: Static EQUIL preservation test -- NO WELLS
% =========================================================================
fprintf('\n=== Stage 8: Static EQUIL preservation test (no wells) ===\n');

% Use the same physical-depth model and the exact gravity head that were
% used for EQUIL initialization. No wells and no boundary conditions.
modelStatic = modelEq;
modelStatic.operators = opEq;

% Avoid the harmless minimum-pressure warning during model validation.
modelStatic.minimumPressure = 1*barsa;

% Ten one-day timesteps. A true hydrostatic/capillary equilibrium should
% remain essentially unchanged.
dt8 = repmat(1*day, 10, 1);
schedule8 = simpleSchedule(dt8);

[wellSols8, states8, report8] = simulateScheduleAD(state0, modelStatic, schedule8); %#ok<ASGLU>

state8 = states8{end};

% Phase ordering.
phaseNames8 = modelStatic.getPhaseNames();
iw8 = find(phaseNames8 == 'W');
io8 = find(phaseNames8 == 'O');
ig8 = find(phaseNames8 == 'G');

dP8  = state8.pressure - state0.pressure;
dSw8 = state8.s(:,iw8) - state0.s(:,iw8);
dSo8 = state8.s(:,io8) - state0.s(:,io8);
dSg8 = state8.s(:,ig8) - state0.s(:,ig8);

fprintf('Simulated time                  : %.6f days\n', sum(dt8)/day);
fprintf('Number of timesteps             : %d\n', numel(states8));
fprintf('Max |Delta P|                   : %.12e bar\n', max(abs(dP8))/barsa);
fprintf('Max |Delta Sw|                  : %.12e\n', max(abs(dSw8)));
fprintf('Max |Delta So|                  : %.12e\n', max(abs(dSo8)));
fprintf('Max |Delta Sg|                  : %.12e\n', max(abs(dSg8)));
fprintf('Mean |Delta P|                  : %.12e bar\n', mean(abs(dP8))/barsa);
fprintf('Cells with |Delta Sw| > 1e-8   : %d\n', nnz(abs(dSw8) > 1e-8));
fprintf('Cells with Sg > 1e-8 at end    : %d\n', nnz(state8.s(:,ig8) > 1e-8));

tolP8 = 1e-5*barsa;
tolS8 = 1e-8;
if max(abs(dP8)) <= tolP8 && ...
   max(abs(dSw8)) <= tolS8 && ...
   max(abs(dSo8)) <= tolS8 && ...
   max(abs(dSg8)) <= tolS8
    fprintf('Stage 8 RESULT                  : PASS -- equilibrium preserved.\n');
else
    fprintf('Stage 8 RESULT                  : CHECK -- measurable drift detected.\n');
end

fprintf('Stage 8 static-equilibrium test completed.\n');

