function activeDir = NewOil_SelectResultsDir(preferredDir)
% Choose a writable directory ONCE per run, before any output is written.
[base, stem] = fileparts(preferredDir);
for k = 0:100
    if k==0, candidate=preferredDir; else, candidate=fullfile(base,sprintf('%s_%d',stem,k)); end
    if exist(candidate,'dir')~=7
        [ok,~]=mkdir(candidate);
        if ~ok, continue; end
    end
    probe=fullfile(candidate,'__NewOil_write_probe__.tmp');
    % Existing output files must not be locked, otherwise use next directory.
    [fid,~]=fopen(probe,'w');
    if fid<0, continue; end
    fclose(fid); delete(probe);
    targets={'checkpoint_v28.mat','production_history.csv','control_events.csv', ...
        'monthly_reports_v27.csv','aquifer_influx.csv','adaptive_benchmark.csv', ...
        'reservoir_states.mat','production_history.mat','00_Model_Parameters.txt'};
    writable=true;
    for j=1:numel(targets)
        f=fullfile(candidate,targets{j});
        if exist(f,'file')==2
            [ff,~]=fopen(f,'a');
            if ff<0, writable=false; break; end
            fclose(ff);
        end
    end
    if writable, activeDir=candidate; return; end
end
error('No writable results directory found');
end
