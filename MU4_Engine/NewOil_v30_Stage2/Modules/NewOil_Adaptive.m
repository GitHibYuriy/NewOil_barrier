% v29 validated controller: unchanged if WELL_SCHEDULE_ENABLED is false.
run(fullfile(inputDir,'NewOil_Schedule_Mode_Input.m'));
if WELL_SCHEDULE_ENABLED
    run(fullfile(rootDir,'Modules','NewOil_Adaptive_Scheduled.m'));
else
%% =========================================================================
% STAGE 11C: CMG-like OPERATE / LIMIT / CONTROL + LRAT RAMP
% =========================================================================
% Control configuration. No BHP minimum switch for CMG comparison.
% OPERATE = requested initial control; LIMIT = admissible conditions;
% CONTROL = event that stops or changes operation.
%
% Scheduling: edit Input/NewOil_ReportCalendar.csv; numerics in Input/NewOil_Numerics_Input.m.
run(fullfile(rootDir,'Modules','NewOil_Calendar.m'));
% Experiment: override the calendar's maximum step; preserve other controls.
run(fullfile(inputDir,'NewOil_Controls_Input.m'));
% =========================================================================
% END USER SETTINGS. No edits are required below this line.
% =========================================================================

fprintf('\n=== STAGE 11B: OPERATE / LIMIT / CONTROL ===\n');
assert(any(strcmpi(OPERATE, {'LRAT','BHP'})), 'OPERATE must be LRAT or BHP');
assert(strcmpi(AQUIFER_COUPLING, 'FULLY_IMPLICIT'), 'Invalid AQUIFER_COUPLING');
assert(AQ_ITER_MAX>=2 && AQ_ITER_RTOL>0 && AQ_ITER_ATOL_M3D>0);
assert(AQ_ITER_RELAX>0 && AQ_ITER_RELAX<=1);

assert(any(strcmpi(ACTION_WCUT, {'STOP','WARNING'})), 'Bad ACTION_WCUT');
assert(any(strcmpi(ACTION_GOR, {'STOP','WARNING'})), 'Bad ACTION_GOR');
assert(SIMULATION_DAYS > 0 && TIMESTEP_DAYS > 0);
assert(LIMIT_BHP_MIN > 0 && LIMIT_LRAT_MAX > 0);
assert(RETURN_CHECK_DAYS > 0 && RETURN_MARGIN_BAR >= 0);
assert(CONTROL_WCUT_MAX >= 0 && CONTROL_WCUT_MAX <= 1);
assert(CONTROL_GOR_MAX > 0);
assert(RAMP_LRAT_START > 0 && RAMP_LRAT_STEP > 0 && RAMP_LRAT_EVERY_DAYS > 0);
assert(~RAMP_LRAT_ENABLED || strcmpi(OPERATE,'LRAT'), ...
    'LRAT ramp requires OPERATE = LRAT');
assert(~RAMP_LRAT_ENABLED || RAMP_LRAT_START <= OPERATE_VALUE, ...
    'RAMP_LRAT_START must not exceed OPERATE_VALUE');
if strcmpi(OPERATE,'LRAT')
    assert(OPERATE_VALUE > 0 && OPERATE_VALUE <= LIMIT_LRAT_MAX, ...
        'Requested LRAT exceeds LIMIT_LRAT_MAX');
    requestedLRAT11 = OPERATE_VALUE;
    initialMode11 = 'lrat';
else
    assert(OPERATE_VALUE >= LIMIT_BHP_MIN, ...
        'Initial BHP must be >= LIMIT_BHP_MIN');
    requestedLRAT11 = LIMIT_LRAT_MAX; % target for possible return
    initialMode11 = 'bhp';
end

modelProd = modelEq;
modelProd.operators = opEq;
modelProd.minimumPressure = 1*barsa;
W11base = W9;
tEnd11 = SIMULATION_DAYS*day;
dtNom11 = TIMESTEP_DAYS*day;
if ~exist('RESULT_DIRECTORY','var') || isempty(RESULT_DIRECTORY)
    RESULT_DIRECTORY = NewOil_SelectResultsDir(fullfile(rootDir,'Results'));
end
resultDir = RESULT_DIRECTORY;
fprintf('Active results directory: %s\n', RESULT_DIRECTORY);
checkpointFile11 = fullfile(RESULT_DIRECTORY,'checkpoint_v28.mat');
historyFile11 = fullfile(RESULT_DIRECTORY,'production_history.csv');
eventsFile11 = fullfile(RESULT_DIRECTORY,'control_events.csv');

config11 = struct('aquiferEnabled',AQ_CT.enabled,'version',280,'OPERATE',OPERATE,'OPERATE_VALUE',OPERATE_VALUE, ...
    'START_SERIAL',START_SERIAL,'DTMIN_DAYS',DTMIN_DAYS,'DTMAX_DAYS',DTMAX_DAYS, ...
    'AQUIFER_COUPLING',AQUIFER_COUPLING,'AQ_ITER_MAX',AQ_ITER_MAX, ...
    'AQ_ITER_RTOL',AQ_ITER_RTOL,'AQ_ITER_ATOL_M3D',AQ_ITER_ATOL_M3D,'AQ_ITER_RELAX',AQ_ITER_RELAX, ...
    'LIMIT_BHP_MIN',LIMIT_BHP_MIN,'LIMIT_LRAT_MAX',LIMIT_LRAT_MAX, ...
    'RAMP_LRAT_ENABLED',RAMP_LRAT_ENABLED,'RAMP_LRAT_START',RAMP_LRAT_START, ...
    'RAMP_LRAT_STEP',RAMP_LRAT_STEP,'RAMP_LRAT_EVERY_DAYS',RAMP_LRAT_EVERY_DAYS, ...
    'ENABLE_BHP_SWITCH',ENABLE_BHP_SWITCH,'RETURN_TO_LRAT',RETURN_TO_LRAT,'RETURN_MARGIN_BAR',RETURN_MARGIN_BAR, ...
    'RETURN_CHECK_DAYS',RETURN_CHECK_DAYS,'CONTROL_WCUT_MAX',CONTROL_WCUT_MAX, ...
    'CONTROL_GOR_MAX',CONTROL_GOR_MAX,'ACTION_WCUT',ACTION_WCUT, ...
    'ACTION_GOR',ACTION_GOR,'wellCells',W11base.cells, ...
    'wellWI',W11base.WI,'numCells',Gax.cells.num);

state11 = state0; t11 = 0; completed11 = false;
aqInflux11 = zeros(0,1); aqCum11 = zeros(0,1);
activeMode11 = initialMode11;
nextReturnCheck11 = 0;
stopReason11 = 'maximum simulation time reached';
time11 = zeros(0,1); dtDone11 = zeros(0,1);
qO11 = zeros(0,1); qW11 = zeros(0,1); qG11 = zeros(0,1);
bhp11 = zeros(0,1); wcut11 = zeros(0,1); gor11 = zeros(0,1);
mode11 = {}; event11 = {}; eventTime11 = zeros(0,1);
eventFrom11 = {}; eventTo11 = {}; eventDetail11 = {};

% Independent experiment: RESTART remains false on the first run.


% Restart accepts a later STOP date. Physical settings must remain identical.
if RESTART
    assert(exist(checkpointFile11,'file')==2, 'No v28 checkpoint found');
    cp11=load(checkpointFile11);
    configCheck11=config11;
    assert(isequaln(cp11.configSaved11,configCheck11), ...
        'Physical settings or timestep limits changed since checkpoint');
    state11=cp11.stateSaved11; t11=cp11.tSaved11;
    AQ_CT=cp11.aquiferSaved11;
    activeMode11=cp11.activeModeSaved11;
    nextReturnCheck11=cp11.nextReturnCheckSaved11;
    time11=cp11.timeSaved11; dtDone11=cp11.dtSaved11;
    qO11=cp11.qOSaved11; qW11=cp11.qWSaved11; qG11=cp11.qGSaved11;
    bhp11=cp11.bhpSaved11; wcut11=cp11.wcutSaved11; gor11=cp11.gorSaved11;
    mode11=cp11.modeSaved11; event11=cp11.eventSaved11;
    eventTime11=cp11.eventTimeSaved11; eventFrom11=cp11.eventFromSaved11;
    eventTo11=cp11.eventToSaved11; eventDetail11=cp11.eventDetailSaved11;
    aqInflux11=cp11.aqInfluxSaved11; aqCum11=cp11.aqCumSaved11;
    assert(t11 < tEnd11-1e-7, 'Checkpoint is at or beyond selected STOP');
    fprintf('RESTART from day %.5f, aquifer influx %.4f m3\n',t11/day,AQ_CT.cumulative);
else
    fprintf('NEW RUN: OPERATE=%s, target %.3f, BHP minimum %.3f bar\n', ...
        upper(activeMode11),requestedLRAT11,LIMIT_BHP_MIN);
end
% All saved steps represent accepted states only.
completed11=false;
stopReason11='calendar STOP date reached';
reportFile11=fullfile(RESULT_DIRECTORY,'monthly_reports_v27.csv');
rejectedSteps11=0; acceptedSteps11=0;
solverCalls11=0; stepWall11=zeros(0,1);
simTimer11=tic;
nextDt11=DTINIT_DAYS*day;
if RESTART, nextDt11=DTMAX_DAYS*day; end

nls11 = NonLinearSolver();
nls11.maxTimestepCuts = 12;
nls11.useRelaxation = true;
nls11.useLinesearch = false;

% Dates are exact integration targets; no interpolation of reservoir states.
while t11 < tEnd11-1e-7 && ~completed11
    nextReport11=find(reportDays11 > t11/day+1e-8,1,'first');
    assert(~isempty(nextReport11),'No next reporting date');
    boundary11=min(tEnd11,reportDays11(nextReport11)*day);
    % Preserve adaptive step capacity when a reporting date truncates the step.
    dtAdaptiveBeforeCalendar11=min(nextDt11,DTMAX_DAYS*day);
    dtCalendarRemaining11=boundary11-t11;
    calendarLimited11=(dtCalendarRemaining11 < dtAdaptiveBeforeCalendar11-1e-7);
    dti11=min(dtAdaptiveBeforeCalendar11,dtCalendarRemaining11);
    trialDtInitial11=dti11;
    assert(dti11>0,'Non-positive timestep');
    % A short step at a report boundary is legitimate even below DTMIN.
    if RAMP_LRAT_ENABLED
        rampIndex11=floor((t11/day+1e-9)/RAMP_LRAT_EVERY_DAYS);
        rampNextDay11=(rampIndex11+1)*RAMP_LRAT_EVERY_DAYS;
        stepLRAT11=min(requestedLRAT11,RAMP_LRAT_START+rampIndex11*RAMP_LRAT_STEP);
        % Once final LRAT is reached, do not enforce further ramp boundaries.
        if stepLRAT11 < requestedLRAT11-1e-10
            dti11=min(dti11,(rampNextDay11-t11/day)*day);
        end
    else
        stepLRAT11=requestedLRAT11;
    end
    % If the rate changed at this step's beginning, start with DTINIT.
    if RAMP_LRAT_ENABLED && ~isempty(time11)
        previousIndex11=floor((time11(end)-dtDone11(end)/day+1e-9)/RAMP_LRAT_EVERY_DAYS);
        currentIndex11=floor((t11/day+1e-9)/RAMP_LRAT_EVERY_DAYS);
        previousTarget11=min(requestedLRAT11,RAMP_LRAT_START+previousIndex11*RAMP_LRAT_STEP);
        if stepLRAT11 > previousTarget11+1e-10 && abs(t11/day-currentIndex11*RAMP_LRAT_EVERY_DAYS)<1e-7
            dti11=min(dti11,DTINIT_DAYS*day);
        end
    end
    % Retry failures from the same accepted state. All updates happen after success.
    success11=false;
    for cut11=0:MAX_STEP_CUTS
        modeBefore11=activeMode11;
        returnBefore11=nextReturnCheck11;
        try
        % Never modify state11/t11 until a candidate is accepted.
        chosenMode11 = activeMode11;
        tryReturn11 = strcmp(activeMode11,'bhp') && RETURN_TO_LRAT && ...
            (t11/day + 1e-9 >= nextReturnCheck11);
        if tryReturn11, chosenMode11 = 'lrat'; end
        accepted11 = false;
        stepEvent11 = 'NONE';
        for attempt11 = 1:2
            W11 = W11base;
            W11.type = chosenMode11;
            W11.lims = struct(); % explicit validation, not implicit MRST switching
            if strcmp(chosenMode11,'lrat')
                W11.val = -stepLRAT11*meter^3/day;
            else
                W11.val = LIMIT_BHP_MIN*barsa;
            end
            scheduleStep11.control = struct('W',W11);

            % Dummy zero-rate source to activate
            % addBoundaryConditionsAndSources in GenericBlackOilModel.
            srcDummy.cell = AQ_CT.cells(1);
            srcDummy.rate = 0;
            srcDummy.sat = [1 0 0];

            scheduleStep11.control.src = srcDummy;

            scheduleStep11.step = struct('val',dti11,'control',1);

            % Fully implicit Fetkovich source: q(p_new) is included in AD
            % Jacobian. Do not set scheduleStep11.control.src for aquifer.
            % Aquifer pressure is frozen for this trial; rejected steps do
            % not modify AQ_CT or the accepted reservoir state.
            modelProd.aquifer = AQ_CT;
            modelProd.aquiferDt = dti11;
            solverCalls11=solverCalls11+1;
            [wsStep11,stStep11] = simulateScheduleAD(state11,modelProd,scheduleStep11, ...
                'NonLinearSolver',nls11);
            assert(~isempty(wsStep11) && ~isempty(stStep11),'MRST returned no solution');
            ws11 = wsStep11{end}(1);
            trialState11 = stStep11{end};
            % Reconstruct accepted implicit source from end-step pressure.
            % The same formula is used inside NewOil_FetkovichModel.
            if AQ_CT.enabled
                pbEndCT = sum(trialState11.pressure(AQ_CT.cells).*AQ_CT.area)/AQ_CT.A;
                qCT = NewOil_Fetkovich_Rate(AQ_CT,pbEndCT,dti11);

            else
                qCT = 0;
            end
            qo11 = -ws11.qOs/(meter^3/day);
            qw11 = -ws11.qWs/(meter^3/day);
            qg11 = -ws11.qGs/(meter^3/day);
            ql11 = qo11+qw11;
            trialBHP11 = ws11.bhp/barsa;
            if strcmp(chosenMode11,'lrat')
                threshold11 = LIMIT_BHP_MIN;
                if tryReturn11, threshold11 = LIMIT_BHP_MIN + RETURN_MARGIN_BAR; end
                if ENABLE_BHP_SWITCH && trialBHP11 < threshold11 - 1e-5
                    % Discard trial; recalculate the SAME step with BHP.
                    stepEvent11 = 'LRAT_REJECTED_BHP_LIMIT';
                    chosenMode11 = 'bhp';
                    tryReturn11 = false;
                    nextReturnCheck11 = t11/day + RETURN_CHECK_DAYS;
                    continue;
                end
            end
            if strcmp(chosenMode11,'bhp') && ql11 > LIMIT_LRAT_MAX + 1e-5
                % BHP alone would exceed rate limit: use LRAT max and verify BHP.
                % If impossible to meet both, stop rather than accept a violation.
                chosenMode11 = 'lrat';
                stepEvent11 = 'BHP_REJECTED_LRAT_LIMIT';
                continue;
            end
            accepted11 = true;
            break;
        end
        if ~accepted11
            error('No feasible OPERATE: BHP_MIN and LRAT_MAX cannot both be satisfied at t=%.2f days',t11/day);
        end
        if strcmp(activeMode11,'lrat') && strcmp(chosenMode11,'bhp')
            stepEvent11 = 'SWITCH_LRAT_TO_BHP';
            nextReturnCheck11 = t11/day + RETURN_CHECK_DAYS;
        elseif strcmp(activeMode11,'bhp') && strcmp(chosenMode11,'lrat')
            stepEvent11 = 'SWITCH_BHP_TO_LRAT';
        end
        if ~isempty(wcut11) && abs(qw11/max(ql11,1e-12)-wcut11(end)) > MAX_WCUT_STEP && dti11 > DTMIN_DAYS*day*(1+1e-8)
            error('ADAPT: WCUT change exceeds tolerance');
        end
        if ~strcmp(activeMode11,chosenMode11)
            eventTime11(end+1,1) = t11/day;
            eventFrom11{end+1,1} = activeMode11;
            eventTo11{end+1,1} = chosenMode11;
            eventDetail11{end+1,1} = stepEvent11;
            fprintf('CONTROL EVENT at %.2f d: %s -> %s (%s)\n', ...
                t11/day,upper(activeMode11),upper(chosenMode11),stepEvent11);
        end
        activeMode11 = chosenMode11;
        state11 = trialState11; t11 = t11+dti11;
        if AQ_CT.enabled
            AQ_CT.Q(end+1,1)=qCT; AQ_CT.dt(end+1,1)=dti11;
            AQ_CT.cumulative=AQ_CT.cumulative+qCT*dti11;
            AQ_CT.pAquifer=AQ_CT.pInit-AQ_CT.cumulative/AQ_CT.C;
        end
        aqInflux11(end+1,1)=qCT*day;
        aqCum11(end+1,1)=AQ_CT.cumulative;
        if abs(ql11) > 1e-12, wc11 = qw11/ql11; else, wc11 = 0; end
        if qo11 > 1e-12, g11 = qg11/qo11; else, g11 = Inf; end
        if strcmp(activeMode11,'bhp') && tryReturn11
            nextReturnCheck11 = t11/day + RETURN_CHECK_DAYS;
        end
        if wc11 >= CONTROL_WCUT_MAX
            stepEvent11 = 'WCUT_LIMIT';
            if strcmpi(ACTION_WCUT,'STOP')
                completed11 = true;
                stopReason11 = sprintf('WCUT %.6f >= %.6f',wc11,CONTROL_WCUT_MAX);
            end
        end
        if g11 >= CONTROL_GOR_MAX && isfinite(CONTROL_GOR_MAX)
            stepEvent11 = 'GOR_LIMIT';
            if strcmpi(ACTION_GOR,'STOP')
                completed11 = true;
                stopReason11 = sprintf('GOR %.6f >= %.6f',g11,CONTROL_GOR_MAX);
            end
        end
        if t11 >= tEnd11, completed11 = true; end
        time11(end+1,1) = t11/day; dtDone11(end+1,1) = dti11;
        qO11(end+1,1) = qo11; qW11(end+1,1) = qw11; qG11(end+1,1) = qg11;
        bhp11(end+1,1) = trialBHP11; wcut11(end+1,1) = wc11; gor11(end+1,1) = g11;
        mode11{end+1,1} = activeMode11; event11{end+1,1} = stepEvent11;
    
    
            success11=true;
            break;
        catch err11
            activeMode11=modeBefore11;
            nextReturnCheck11=returnBefore11;
            rejectedSteps11=rejectedSteps11+1;
            if dti11/2 < DTMIN_DAYS*day && dti11 > DTMIN_DAYS*day*(1+1e-8)
                dti11=DTMIN_DAYS*day;
            elseif dti11 <= DTMIN_DAYS*day*(1+1e-8)
                rethrow(err11);
            else
                dti11=dti11/2;
            end
            fprintf('RETRY at %.4f d: dt=%.5f d (%s)\n',t11/day,dti11/day,err11.message);
        end
    end
    assert(success11,'Adaptive step retries exhausted');
    acceptedSteps11=acceptedSteps11+1;
    stepWall11(end+1,1)=toc(simTimer11);
    % A calendar-only short step must not reset the next month's adaptive dt.
    % If an external retry reduced this step, keep the reduced value instead.
    if calendarLimited11 && abs(dti11-trialDtInitial11)<1e-7
        nextDt11=dtAdaptiveBeforeCalendar11;
    else
        nextDt11=min(DTMAX_DAYS*day,max(DTMIN_DAYS*day,dti11*DTGROW));
    end
    % After a rate-target change, restart adaptive timestep growth.
    if RAMP_LRAT_ENABLED && numel(time11)>1
        prevRampIdx11=floor((time11(end-1)+1e-9)/RAMP_LRAT_EVERY_DAYS);
        nowRampIdx11=floor((time11(end)+1e-9)/RAMP_LRAT_EVERY_DAYS);
        prevTarget11=min(requestedLRAT11,RAMP_LRAT_START+prevRampIdx11*RAMP_LRAT_STEP);
        nowTarget11=min(requestedLRAT11,RAMP_LRAT_START+nowRampIdx11*RAMP_LRAT_STEP);
        if nowTarget11>prevTarget11+1e-10, nextDt11=DTINIT_DAYS*day; end
    end
    if numel(mode11)>1 && ~strcmp(mode11{end},mode11{end-1})
        nextDt11=DTINIT_DAYS*day;
    end
    atReport11=abs(t11/day-reportDays11(nextReport11))<1e-7;
    if atReport11 || completed11
        displayMode11=upper(activeMode11);
        if strcmpi(activeMode11,'lrat'), displayMode11='Liquid_rate'; end
        fprintf('REPORT %s | t=%.4f d | OPERATE=%s | Np=%.3f m3 Wp=%.3f m3 Gp=%.6f MMm3 | Qo=%.5f Qw=%.5f WCUT=%.5f BHP=%.5f | AQ=%.3f\n', ...
            datestr(START_SERIAL+t11/day,'yyyy-mm-dd'),t11/day,displayMode11, ...
            sum(qO11.*dtDone11/day),sum(qW11.*dtDone11/day),sum(qG11.*dtDone11/day)/1e6, ...
            qO11(end),qW11(end),wcut11(end),bhp11(end),AQ_CT.cumulative);
        % Save complete aquifer and all accepted-step histories for reliable RESTART.
        configSaved11=config11; stateSaved11=state11; tSaved11=t11;
        aquiferSaved11=AQ_CT; activeModeSaved11=activeMode11;
        nextReturnCheckSaved11=nextReturnCheck11;
        timeSaved11=time11; dtSaved11=dtDone11;
        qOSaved11=qO11; qWSaved11=qW11; qGSaved11=qG11;
        bhpSaved11=bhp11; wcutSaved11=wcut11; gorSaved11=gor11;
        modeSaved11=mode11; eventSaved11=event11;
        eventTimeSaved11=eventTime11; eventFromSaved11=eventFrom11;
        eventToSaved11=eventTo11; eventDetailSaved11=eventDetail11;
        aqInfluxSaved11=aqInflux11; aqCumSaved11=aqCum11;
        try
        checkpointTmp11=[checkpointFile11,'.tmp'];
        save('-mat7-binary',checkpointTmp11,'configSaved11','stateSaved11','tSaved11', ...
            'aquiferSaved11','activeModeSaved11','nextReturnCheckSaved11', ...
            'timeSaved11','dtSaved11','qOSaved11','qWSaved11','qGSaved11', ...
            'bhpSaved11','wcutSaved11','gorSaved11','modeSaved11','eventSaved11', ...
            'eventTimeSaved11','eventFromSaved11','eventToSaved11','eventDetailSaved11', ...
            'aqInfluxSaved11','aqCumSaved11');
        [ok11,msg11]=movefile(checkpointTmp11,checkpointFile11,'f');
        if ~ok11
            backupCp11=[checkpointFile11,'.pending'];
            [backupOk11,backupMsg11]=movefile(checkpointTmp11,backupCp11,'f');
            if backupOk11
                warning('Checkpoint primary locked; latest state in %s',backupCp11);
            else
                warning('Checkpoint could not be replaced or backed up: %s / %s',msg11,backupMsg11);
            end
        end
        % Accepted-step history: control target, cumulative volumes, then rates.
        [fidHist11,~]=NewOil_SafeFopen(historyFile11);
        if fidHist11>=0
        fprintf(fidHist11,'Time_d,dt_d,OPERATE,Volume,Np_m3,Wp_m3,Gp_m3,Qo_m3d,Qw_m3d,Qg_m3d,QL_m3d,WCUT,GOR,BHP_bar,Event\n');
        npHist11=0; wpHist11=0; gpHist11=0;
        for kh11=1:numel(time11)
            npHist11=npHist11+qO11(kh11)*dtDone11(kh11)/day;
            wpHist11=wpHist11+qW11(kh11)*dtDone11(kh11)/day;
            gpHist11=gpHist11+qG11(kh11)*dtDone11(kh11)/day;
            if strcmpi(mode11{kh11},'lrat')
                if RAMP_LRAT_ENABLED
                    stepStartDay11=time11(kh11)-dtDone11(kh11)/day;
                    idxHist11=floor((stepStartDay11+1e-9)/RAMP_LRAT_EVERY_DAYS);
                    volumeHist11=min(requestedLRAT11,RAMP_LRAT_START+idxHist11*RAMP_LRAT_STEP);
                else
                    volumeHist11=requestedLRAT11;
                end
            else
                volumeHist11=LIMIT_BHP_MIN; % BHP mode: target pressure, bar
            end
            modeLabelHist11=mode11{kh11};
            if strcmpi(modeLabelHist11,'lrat'), modeLabelHist11='Liquid_rate'; end
            fprintf(fidHist11,'%.10g,%.10g,%s,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%s\n', ...
                time11(kh11),dtDone11(kh11)/day,modeLabelHist11,volumeHist11, ...
                npHist11,wpHist11,gpHist11,qO11(kh11),qW11(kh11),qG11(kh11), ...
                qO11(kh11)+qW11(kh11),wcut11(kh11),gor11(kh11),bhp11(kh11),event11{kh11});
        end
        fclose(fidHist11);
        end
        [fidAq11,~]=NewOil_SafeFopen(fullfile(RESULT_DIRECTORY,'aquifer_influx.csv'));
        if fidAq11>=0
        fprintf(fidAq11,'Time_d,Influx_m3d,CumulativeInflux_m3\n');
        for ka11=1:numel(time11)
            fprintf(fidAq11,'%.10g,%.10g,%.10g\n',time11(ka11),aqInflux11(ka11),aqCum11(ka11));
        end
        fclose(fidAq11);
        end
        [fidEv11,~]=NewOil_SafeFopen(eventsFile11);
        if fidEv11>=0
        fprintf(fidEv11,'Time_d,OldOPERATE,NewOPERATE,Reason\n');
        for ke11=1:numel(eventTime11)
            fprintf(fidEv11,'%.10g,%s,%s,%s\n',eventTime11(ke11), ...
                eventFrom11{ke11},eventTo11{ke11},eventDetail11{ke11});
        end
        fclose(fidEv11);
        end
        % Rebuild report CSV from accepted steps on report boundaries.
        [fid11,~]=NewOil_SafeFopen(reportFile11);
        if fid11>=0
        fprintf(fid11,'Date,Time_d,OPERATE,Qo_m3d,Qw_m3d,WCUT,BHP_bar,Np_m3,Wp_m3,Aquifer_m3\n');
        np11=cumsum(qO11.*dtDone11/day); wp11=cumsum(qW11.*dtDone11/day);
        for r11=1:numel(reportDays11)
            k11=find(abs(time11-reportDays11(r11))<1e-7,1,'last');
            if isempty(k11),continue;end
            modeLabelReport11=mode11{k11};
            if strcmpi(modeLabelReport11,'lrat'), modeLabelReport11='Liquid_rate'; end
            fprintf(fid11,'%s,%.10g,%s,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g\n', ...
                datestr(START_SERIAL+time11(k11),'yyyy-mm-dd'),time11(k11),modeLabelReport11, ...
                qO11(k11),qW11(k11),wcut11(k11),bhp11(k11),np11(k11),wp11(k11),aqCum11(k11));
        end
        fclose(fid11);
        end
        catch saveErr11
            warning('Nonfatal report/checkpoint save error at day %.4f: %s',t11/day,saveErr11.message);
        end
    end
end

% Benchmark: wall-clock time of Stage 11B including report/checkpoint I/O.
elapsed11=toc(simTimer11);
if ~isempty(dtDone11)
    meanDt11=mean(dtDone11)/day;
    maxDt11=max(dtDone11)/day;
else
    meanDt11=NaN; maxDt11=NaN;
end
fprintf('\n=== ADAPTIVE BENCHMARK (DTMAX=%.3f d) ===\n',DTMAX_DAYS);
fprintf('Wall time: %.3f s | Accepted: %d | Rejected: %d | Solver calls: %d\n', ...
    elapsed11,acceptedSteps11,rejectedSteps11,solverCalls11);
fprintf('Mean accepted dt: %.6f d | Max accepted dt: %.6f d\n',meanDt11,maxDt11);
benchmarkFile11=fullfile(RESULT_DIRECTORY,'adaptive_benchmark.csv');
[fidBench11,~]=NewOil_SafeFopen(benchmarkFile11);
if fidBench11>=0
    fprintf(fidBench11,'DTMAX_d,Elapsed_s,Accepted_steps,Rejected_steps,Solver_calls,Mean_dt_d,Max_dt_d,Time_d,Aquifer_m3,BHP_bar,WCUT,Np_m3,Wp_m3\n');
    fprintf(fidBench11,'%.10g,%.10g,%d,%d,%d,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g,%.10g\n', ...
        DTMAX_DAYS,elapsed11,acceptedSteps11,rejectedSteps11,solverCalls11, ...
        meanDt11,maxDt11,t11/day,AQ_CT.cumulative,bhp11(end),wcut11(end), ...
        sum(qO11.*dtDone11/day),sum(qW11.*dtDone11/day));
    fclose(fidBench11);
else
    warning('Cannot write adaptive_benchmark.csv');
end

fprintf('\nStage 11B final results:\n');
if AQ_CT.enabled, fprintf('Aquifer cumulative influx = %.6f m3\n',AQ_CT.cumulative); end
fprintf('Stop reason: %s\n',stopReason11);
if ~isempty(time11)
    fprintf('Time %.2f d; steps %d; final OPERATE %s\n', ...
        time11(end),numel(time11), ...
        strrep(upper(activeMode11),'LRAT','Liquid_rate'));
    fprintf('Qo %.6f, Qw %.6f, QL %.6f m3/day; WCUT %.6f; BHP %.6f bar\n', ...
        qO11(end),qW11(end),qO11(end)+qW11(end),wcut11(end),bhp11(end));
    fprintf('Np %.6f, Wp %.6f m3\n', ...
        sum(qO11.*dtDone11/day),sum(qW11.*dtDone11/day));
end
fprintf('Control transitions: %d\n',numel(eventTime11));
fprintf('Results saved in: %s\n',RESULT_DIRECTORY);

% ============================================================

NewOil_BalanceReport(state11,modelProd,fluid,rock,state0,AQ_CT, ...
    sum(qO11.*dtDone11/day),sum(qW11.*dtDone11/day), ...
    sum(qG11.*dtDone11/day),t11/day,RESULT_DIRECTORY);

end
