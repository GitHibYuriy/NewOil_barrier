function CSP2_Main()
% SPE CSP-2 SI; independent project. Requires MRST ad-core, ad-props, ad-blackoil, deckformat.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'Modules'));
try
    mrstModule add ad-core ad-props ad-blackoil deckformat
catch ME
    error('MRST is not initialized. Run mrstModule add ... first. %s',ME.message);
end
D=CSP2_LoadInputs(root);
outputDir=fullfile(root,'Results'); if ~exist(outputDir,'dir'),mkdir(outputDir);end
fprintf('\n=== SPE CSP-2, MRST SI ===\n');
[G,rock,depth,op,geom]=CSP2_Grid(D);
deckPath=fullfile(outputDir,'CSP2_generated_ECLIPSE.DATA');
CSP2_WriteDeck(D,deckPath);
deck=convertDeckUnits(readEclipseDeck(deckPath));
fluid=initDeckADIFluid(deck,'G',G,'region_method','override', ...
  'regionOverride',struct('PVTNUM',':','SATNUM',':','ROCKNUM',':','IMBNUM',':','SURFNUM',':'));
model=GenericBlackOilModel(G,rock,fluid,'water',true,'oil',true,'gas',true, ...
  'disgas',true,'vapoil',false);
model.operators=op;
% Explicit physical depth gradient (depth positive downward).
model.operators.gdz=op.Grad(depth(:))*D.model.gravity_m_s2;
% Initial equilibrium: use deck-based EQUIL, not an invented sharp contact.
modelEq=model;
modelEq.G.cells.centroids(:,3)=depth(:);
modelEq.gravity=[0,0,D.model.gravity_m_s2];
modelEq.operators=model.operators;
state0=initStateDeck(modelEq,deck);
assert(all(isfinite(state0.pressure)) && all(isfinite(state0.s(:))));
assert(max(abs(sum(state0.s,2)-1))<1e-6);
fprintf('Initial pressure %.3f..%.3f bar; Sw %.4f..%.4f; Sg %.4f..%.4f\n', ...
 min(state0.pressure)/1e5,max(state0.pressure)/1e5, ...
 min(state0.s(:,1)),max(state0.s(:,1)),min(state0.s(:,3)),max(state0.s(:,3)));
[W,wellMeta]=CSP2_Well(D,G,rock,depth,geom);
% Completion-level diagnostics before the first step.
fid=fopen(fullfile(outputDir,'CSP2_initial_completion_diagnostics.csv'),'w');
if fid>=0
 fprintf(fid,'cell,depth_m,pressure_kPa,Sw,So,Sg,WI_SI\n');
 for j=1:numel(W.cells)
  c=W.cells(j);
  fprintf(fid,'%d,%.9g,%.9g,%.9g,%.9g,%.9g,%.9g\n', ...
   c,depth(c),state0.pressure(c)/1000,state0.s(c,1),state0.s(c,2),state0.s(c,3),W.WI(j));
  fprintf('Completion cell=%d: Sw=%.6f So=%.6f Sg=%.6f P=%.3f kPa WI=%.6g\n', ...
   c,state0.s(c,1),state0.s(c,2),state0.s(c,3),state0.pressure(c)/1000,W.WI(j));
 end
 fclose(fid);
end

% Run in calendar-aligned adaptive steps, retry with halved dt on failure.
[history,lastState]=CSP2_Run(D,model,state0,W,outputDir);
save(fullfile(outputDir,'CSP2_final_state.mat'),'lastState','history','wellMeta');
CSP2_Report(history,outputDir);
fprintf('Completed: see Results/CSP2_history.csv and CSP2_summary.txt\n');
end
