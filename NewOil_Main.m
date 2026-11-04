% NewOil_Radial_v26 Fetkovich - modular R-Z prototype (GNU Octave / MRST)
clear; clc;
rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir); addpath(fullfile(rootDir,'Modules'));
mrstModule add ad-core ad-props ad-blackoil deckformat
inputDir = fullfile(rootDir,'Input');
resultDir = NewOil_SelectResultsDir(fullfile(rootDir,'Results'));
RESULT_DIRECTORY = resultDir;
fprintf('Selected results directory: %s\n', resultDir);
% Scripts share the main workspace; split from validated v20 stages.
run(fullfile(rootDir,'Modules','NewOil_Grid.m'));
run(fullfile(rootDir,'Modules','NewOil_PVT_Tables.m'));
run(fullfile(rootDir,'Modules','NewOil_Operators.m'));
run(fullfile(rootDir,'Modules','NewOil_PVT.m'));
run(fullfile(rootDir,'Modules','NewOil_InitialState.m'));
disp('=== CHECK INITIAL STATE ===');

[I,J] = ind2sub(model.G.cartDims, model.G.cells.indexMap);
idx = find(I == 1 & J <= 18);

disp('Cell    Layer    Sw    So    Sg');
disp([idx(:), J(idx(:))(:), state0.s(idx,:)]);


% Optional: run(fullfile(rootDir,'Modules','NewOil_StaticTest.m'));
run(fullfile(rootDir,'Modules','NewOil_Wells.m'));
run(fullfile(rootDir,'Modules','NewOil_Aquifer.m'));
NewOil_BalanceReport(state0,modelEq,fluid,rock,state0,AQ_CT,0,0,0,0,resultDir);
run(fullfile(rootDir,'Modules','NewOil_Adaptive.m'));
run(fullfile(rootDir,'Modules','NewOil_Results.m'));
run(fullfile(rootDir,'Modules','NewOil_Save.m'));
% Final metadata report: OWC is read from deck EQUIL, if present.
owcReport = NaN;
if isfield(deckFluid,'SOLUTION') && isfield(deckFluid.SOLUTION,'EQUIL')
    equilReport = deckFluid.SOLUTION.EQUIL;
    if size(equilReport,2)>=3, owcReport = equilReport(1,3); end
end
NewOil_ModelParametersReport(RESULT_DIRECTORY,fluidInput,rEdge,BARRIER_ENABLED,BARRIER_I,BARRIER_K,rock,milli*darcy,INITIAL_PRESSURE_KPA,INITIAL_REFERENCE_DEPTH_M,owcReport);
