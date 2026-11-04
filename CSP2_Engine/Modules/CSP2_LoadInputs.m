function D = CSP2_LoadInputs(projectDir)
% Load SI data extracted directly from validated CMG CSP-2 deck.
% Input JSON is a source description, not yet an MRST simulation deck.
if nargin < 1 || isempty(projectDir)
    projectDir = fileparts(fileparts(mfilename('fullpath')));
end
p = fullfile(projectDir, 'Input', 'CSP2_SI.json');
fid = fopen(p,'r'); assert(fid >= 0, 'Cannot open %s',p);
raw = fread(fid,'*char')'; fclose(fid);
D = jsondecode(raw);
assert(numel(D.grid.dr_m)==D.grid.dimensions(1) && numel(D.grid.dz_m)==D.grid.dimensions(3));
assert(numel(D.grid.poro_by_layer)==D.grid.dimensions(3));
assert(all(D.grid.dr_m(:)>0) && all(D.grid.dz_m(:)>0));
assert(all(D.grid.poro_by_layer(:)>0) && all(D.grid.poro_by_layer(:)<1));
assert(all(D.grid.k_horizontal_mD_by_layer(:)>0) && all(D.grid.k_vertical_mD_by_layer(:)>0));
assert(all(diff(D.well.oil_rate_schedule_days_m3_day(:,1))>0));
assert(D.numerics.initial_dt_days>0 && D.numerics.max_dt_days>=D.numerics.initial_dt_days);
assert(D.numerics.min_dt_days>0 && D.numerics.max_attempts>=1);
assert(size(D.fluid.PVT,2)==6 && size(D.fluid.PVT,1)==14);
assert(size(D.fluid.SWT,2)==4 && size(D.fluid.SLT,2)==4);
assert(all(diff(D.fluid.PVT(:,1))>0));
assert(all(diff(D.fluid.SWT(:,1))>0));
assert(all(diff(D.fluid.SLT(:,1))>0));
fprintf('CSP-2 SI input validated: grid %dx%dx%d, PVT %d rows, SWT %d, SLT %d.\n', ...
  D.grid.dimensions(1),D.grid.dimensions(2),D.grid.dimensions(3), ...
  size(D.fluid.PVT,1),size(D.fluid.SWT,1),size(D.fluid.SLT,1));
end
