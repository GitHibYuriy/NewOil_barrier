% NewOil_v30: static input checks, no MRST needed.
rootDir = fileparts(mfilename('fullpath'));
inputDir = fullfile(rootDir,'Input');
required = {'NewOil_Grid_Input.m','NewOil_Wells_Input.m', ...
 'NewOil_Controls_Input.m','NewOil_Initialization_Input.m', ...
 'NewOil_Numerics_Input.m','NewOil_Aquifer_Input.m', ...
 'NewOil_ReportCalendar.csv','NewOil_Fluid_PVT.DATA','EclipseShablon.DATA'};
for k=1:numel(required)
 f=fullfile(inputDir,required{k});
 assert(exist(f,'file')==2,['Missing Input: ',f]);
 fprintf('OK: %s\n',required{k});
end
run(fullfile(inputDir,'NewOil_Grid_Input.m'));
assert(numel(dr)>0 && numel(dz)>0 && all(dr>0) && all(dz>0));
assert(numel(dtop)==numel(dr));
run(fullfile(inputDir,'NewOil_Wells_Input.m'));
assert(all(WELL_PERF_K>=1) && all(WELL_PERF_K<=numel(dz)));
assert(WELL_RADIAL_I>=1 && WELL_RADIAL_I<=numel(dr));
run(fullfile(inputDir,'NewOil_Numerics_Input.m'));
run(fullfile(inputDir,'NewOil_Aquifer_Input.m'));
run(fullfile(inputDir,'NewOil_Initialization_Input.m'));
START_SERIAL=datenum(START_DATE,'yyyy-mm-dd');
STOP_SERIAL=START_SERIAL+1; % static validation of controls only
run(fullfile(inputDir,'NewOil_Controls_Input.m'));
assert(any(strcmpi(OPERATE,{'LRAT','BHP'})));
assert(OPERATE_VALUE>0 && LIMIT_BHP_MIN>0);
fprintf('Static input checks passed. MRST simulation NOT executed.\n');
