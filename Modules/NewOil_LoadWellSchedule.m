% One well; CSV columns TIME_DAY,MODE,TARGET,BHP_MIN_KPA,WCUT_MAX,GOR_MAX
WELL_SCHEDULE_ROWS=[]; WELL_SCHEDULE_MODES={};
if ~WELL_SCHEDULE_ENABLED, return; end
fname=fullfile(inputDir,'WellSchedule.csv');
fid=fopen(fname,'r'); assert(fid>=0,['Missing ',fname]);
cleanup=onCleanup(@() fclose(fid));
header=fgetl(fid);
assert(ischar(header),'Empty WellSchedule.csv');
while true
    line=fgetl(fid);
    if ~ischar(line), break; end
    line=strtrim(line);
    if isempty(line) || line(1)=='#', continue; end
    parts=strsplit(strrep(line,';',','),',');
    assert(numel(parts)==6,['Bad WellSchedule row: ',line]);
    mode=upper(strtrim(parts{2}));
    assert(any(strcmp(mode,{'ORAT','LRAT','BHP'})), 'Unsupported schedule MODE');
    nums=zeros(1,5);
    indices=[1,3,4,5,6];
    for j=1:5
        x=strtrim(parts{indices(j)});
        if isempty(x) && j==4, nums(j)=Inf;
        elseif isempty(x) && j==5, nums(j)=Inf;
        else, nums(j)=str2double(x); end
    end
    assert(isfinite(nums(1)) && nums(1)>=0,'Invalid TIME_DAY');
    assert(isfinite(nums(2)) && nums(2)>0,'Invalid TARGET');
    assert(isfinite(nums(3)) && nums(3)>0,'Invalid BHP_MIN_KPA');
    assert((isinf(nums(4)) || (nums(4)>0 && nums(4)<=1)) && nums(5)>0,'Invalid shutdown thresholds');
    if strcmp(mode,'BHP'), assert(nums(2)>=nums(3),'BHP target below minimum'); end
    WELL_SCHEDULE_ROWS(end+1,:)=nums;
    WELL_SCHEDULE_MODES{end+1,1}=mode;
end
assert(~isempty(WELL_SCHEDULE_ROWS) && WELL_SCHEDULE_ROWS(1,1)==0,'Schedule must start at day zero');
assert(all(diff(WELL_SCHEDULE_ROWS(:,1))>0),'Schedule times must be strictly increasing');
assert(WELL_SCHEDULE_ROWS(end,1)<SIMULATION_DAYS,'Schedule event must precede STOP');
% Override only the scheduled controller; legacy defaults are preserved otherwise.
OPERATE=WELL_SCHEDULE_MODES{1};
OPERATE_VALUE=WELL_SCHEDULE_ROWS(1,2);
LIMIT_BHP_MIN=WELL_SCHEDULE_ROWS(1,3)/100;
CONTROL_WCUT_MAX=WELL_SCHEDULE_ROWS(1,4);
CONTROL_GOR_MAX=WELL_SCHEDULE_ROWS(1,5);
RAMP_LRAT_ENABLED=false;
ENABLE_BHP_SWITCH=true;
RETURN_TO_LRAT=true;
fprintf('Loaded %d well schedule stages\n',size(WELL_SCHEDULE_ROWS,1));
