function [H,state]=CSP2_Run(D,model,state,Wbase,outdir)
% Experimental CSP2 solver. Rate control is retried under BHP on violation.
% Units: time day, pressure kPa, surface rates m3/day.
sch=D.well.oil_rate_schedule_days_m3_day;
endDay=D.well.end_day; minBHP=D.well.min_BHP_kPa*1000;
N=D.numerics;
t=0;dt=N.initial_dt_days;dtMax=N.max_dt_days;dtMin=N.min_dt_days;dtGrow=N.dt_growth_factor;
H=zeros(0,13);nAccepted=0;nRejected=0;events={};
nls=NonLinearSolver(); nls.useRelaxation=N.nonlinear_relaxation;
lastMode='';stopReason='end_day';
while t<endDay-N.schedule_tolerance_days
 ix=find(sch(:,1)<=t+N.schedule_tolerance_days,1,'last'); target=sch(ix,2);
 nextIx=find(sch(:,1)>t+10*N.schedule_tolerance_days,1,'first');
 if isempty(nextIx), nextEvent=endDay; else, nextEvent=sch(nextIx,1); end
 dt=min([dt,dtMax,nextEvent-t,endDay-t]);
 assert(dt>0,'Nonpositive CSP2 timestep');
 accepted=false; trialMode='orat';
 for attempt=1:N.max_attempts
  W=Wbase; W.type=trialMode; W.status=true;
  if strcmp(trialMode,'orat'),W.val=-target*meter^3/day;
  else,W.val=minBHP;end
  W.lims=struct();
  schedule.control=struct('W',W);
  schedule.step=struct('val',dt*day,'control',1);
  try
   [ws,ss]=simulateScheduleAD(state,model,schedule,'NonLinearSolver',nls);
   assert(~isempty(ws)&&~isempty(ss),'Empty MRST output');
   well=ws{end}(1);trial=ss{end};
   assert(all(isfinite(trial.pressure))&&all(isfinite(trial.s(:))),'Nonfinite reservoir state');
   wellOpen=isfield(well,'status') && logical(well.status);
   qoTrial=-well.qOs*day;
   if strcmp(trialMode,'orat') && (~wellOpen || ~isfinite(qoTrial) || qoTrial<=N.minimum_oil_rate_m3_day)
    fprintf('CONTROL at %.6f d: ORAT -> BHP; status=%d, Qo=%.8g m3/day, BHP=%.3f kPa\n', ...
       t,wellOpen,qoTrial,well.bhp/1000);
    trialMode='bhp';continue;
   end
   if strcmp(trialMode,'orat') && well.bhp<minBHP-N.pressure_tolerance_kPa*1000
    fprintf('CONTROL at %.6f d: ORAT -> BHP (trial BHP %.3f kPa below %.3f)\n', ...
      t,well.bhp/1000,minBHP/1000);
    trialMode='bhp';continue;
   end
   if strcmp(trialMode,'bhp') && ~wellOpen
    error('BHP_DIAGNOSTIC: MRST closed well at prescribed minimum BHP');
   end
   if strcmp(trialMode,'bhp') && well.bhp<minBHP-N.bhp_tolerance_kPa*1000
    error('BHP-controlled solution violates minimum BHP');
   end
   accepted=true;break;
  catch ME
   % Do not hide a closed well under endless timestep halvings.
   if strcmp(trialMode,'orat')
    fprintf('CONTROL at %.6f d: ORAT solve failed (%s); retrying BHP at same dt\n',t,ME.message);
    trialMode='bhp';continue;
   end
   nRejected=nRejected+1;
   fprintf('Rejected t=%.6f dt=%.7f mode=%s: %s\n',t,dt,trialMode,ME.message);
   if ~isempty(strfind(ME.message,'BHP_DIAGNOSTIC'))
    error('CSP2 well closed even in BHP mode at day %.8f. Inspect completion WI, initial saturation, phase mobility and pressure reference.',t);
   end
   dt=dt/2;trialMode='orat';
   if dt<dtMin,error('CSP2 timestep below minimum at day %.8f: %s',t,ME.message);end
  end
 end
 if ~accepted,error('CSP2 failed at t=%.8f days',t);end
 if ~strcmp(trialMode,lastMode)
  events(end+1,:)={t,lastMode,trialMode}; lastMode=trialMode;
 end
 t=t+dt;state=trial;nAccepted=nAccepted+1;
 qo=-well.qOs*day; qw=-well.qWs*day; qg=-well.qGs*day;
 % Undefined ratios are NaN at zero production; never report WCUT > 1.
 qo=max(0,qo);qw=max(0,qw);qg=max(0,qg);
 if qo+qw>1e-9,wcut=qw/(qo+qw);else,wcut=NaN;end
 if qo>1e-9,gor=qg/qo;else,gor=NaN;end
 if isempty(H),Np=qo*dt;Wp=qw*dt;Gp=qg*dt;
 else,Np=H(end,9)+qo*dt;Wp=H(end,10)+qw*dt;Gp=H(end,11)+qg*dt;end
 H(end+1,:)=[t,dt,well.bhp/1000,qo,qw,qg,wcut,gor,Np,Wp,Gp,strcmp(trialMode,'bhp'),double(well.status)];
 fprintf('t=%8.3f d | BHP=%9.2f kPa | Qo=%9.4f Qw=%9.4f Qg=%10.3f | WCUT=%7.4f GOR=%9.3f | %s status=%d\n', ...
 t,well.bhp/1000,qo,qw,qg,wcut,gor,trialMode,well.status);
 if isfield(D.well,'wcut_max') && isfinite(D.well.wcut_max) && isfinite(wcut) && wcut>=D.well.wcut_max
  stopReason='WCUT limit';break;
 end
 if isfield(D.well,'gor_max') && isfinite(D.well.gor_max) && isfinite(gor) && gor>=D.well.gor_max
  stopReason='GOR limit';break;
 end
 dt=min(dt*dtGrow,dtMax);
 if mod(nAccepted,N.checkpoint_interval_steps)==0
  save(fullfile(outdir,'CSP2_checkpoint.mat'),'state','H','t','nAccepted','nRejected');
 end
end
fid=fopen(fullfile(outdir,'CSP2_control_events.csv'),'w');
if fid>=0
 fprintf(fid,'time_day,from_mode,to_mode\n');
 for j=1:size(events,1),fprintf(fid,'%.9f,%s,%s\n',events{j,1},events{j,2},events{j,3});end
 fclose(fid);
end
fprintf('CSP2: accepted=%d rejected=%d stop=%s at day %.6f\n',nAccepted,nRejected,stopReason,t);
end
