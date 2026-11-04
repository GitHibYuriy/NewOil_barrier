% STAGE 4: read and validate the ONE user-maintained fluid input file.
% NewOil-specific keyword format, not an ECLIPSE parser.
pvtSourceFile = fullfile(inputDir, 'NewOil_Fluid_PVT.DATA');
assert(exist(pvtSourceFile,'file') == 2, ['Missing fluid file: ', pvtSourceFile]);
fid = fopen(pvtSourceFile, 'r'); assert(fid >= 0);
fluidInput = struct();
key = ''; buf = [];
while true
    line = fgetl(fid);
    if ~ischar(line), break; end
    line = regexprep(line, '--.*$', '');
    line = regexprep(line, '#.*$', '');
    line = strtrim(line);
    if isempty(line), continue; end
    if isempty(key)
        tok = strsplit(line); tag = upper(tok{1});
        if any(strcmp(tag, {'MODEL','TRES','INTERPOLATION','EXTRAPOLATION'}))
            assert(numel(tok)==2, ['Invalid keyword: ',tag]);
            fluidInput.(tag) = tok{2};
        elseif any(strcmp(tag, {'DENSITY','PVTW','PVT6','PVTO_UNSAT','SWOF','SGOF'}))
            key = tag; buf = [];
        else
            error(['Unknown fluid input keyword: ',tag]);
        end
    else
        finished = ~isempty(strfind(line,'/'));
        line = strrep(line,'/',' ');
        vals = sscanf(line,'%f')';
        if ~isempty(strtrim(line))
            assert(~isempty(vals), ['Non-numeric row in ',key]);
            if isempty(buf), buf=vals; else
                assert(size(buf,2)==numel(vals), ['Wrong column count in ',key]);
                buf(end+1,:)=vals;
            end
        end
        if finished
            fluidInput.(key)=buf; key=''; buf=[];
        end
    end
end
fclose(fid);
assert(isempty(key), 'Unterminated fluid input table');
req={'MODEL','TRES','DENSITY','PVTW','PVT6','PVTO_UNSAT','SWOF','SGOF','INTERPOLATION','EXTRAPOLATION'};
for j=1:numel(req), assert(isfield(fluidInput,req{j}), ['Missing ',req{j}]); end
assert(strcmpi(fluidInput.MODEL,'BLACKOIL'),'Only BLACKOIL supported');
assert(strcmpi(fluidInput.INTERPOLATION,'LINEAR'),'Only LINEAR supported');
assert(strcmpi(fluidInput.EXTRAPOLATION,'ERROR'),'Only ERROR supported');
assert(isfinite(str2double(fluidInput.TRES)),'Invalid TRES');
assert(numel(fluidInput.DENSITY)==3 && all(fluidInput.DENSITY>0));
assert(numel(fluidInput.PVTW)==5 && all(fluidInput.PVTW(1:4)>0));
assert(size(fluidInput.PVT6,2)==6 && size(fluidInput.PVT6,1)>=2);
assert(size(fluidInput.PVTO_UNSAT,2)==3 && size(fluidInput.PVTO_UNSAT,1)>=2);
assert(size(fluidInput.SWOF,2)==4 && size(fluidInput.SGOF,2)==4);
assert(all(diff(fluidInput.PVT6(:,1))>0),'PVT6 pressure order');
assert(all(diff(fluidInput.PVT6(:,2))>=0),'PVT6 Rs order');
assert(all(all(fluidInput.PVT6(:,3:6)>0)),'PVT6 Bo/Bg/mu must be positive');
assert(all(diff(fluidInput.PVTO_UNSAT(:,1))>0),'PVTO_UNSAT pressure order');
assert(all(all(fluidInput.PVTO_UNSAT(:,2:3)>0)),'PVTO_UNSAT Bo/mu must be positive');
assert(all(diff(fluidInput.SWOF(:,1))>0) && all(diff(fluidInput.SGOF(:,1))>0));
assert(all(fluidInput.SWOF(:,1)>=0 & fluidInput.SWOF(:,1)<=1));
assert(all(fluidInput.SGOF(:,1)>=0 & fluidInput.SGOF(:,1)<=1));
assert(all(all(fluidInput.SWOF(:,2:3)>=0)) && all(all(fluidInput.SGOF(:,2:3)>=0)));
assert(abs(fluidInput.PVT6(end,1)-fluidInput.PVTO_UNSAT(1,1))<1e-6, ...
       'PVTO_UNSAT must start at bubblepoint');
assert(max(abs(fluidInput.PVT6(end,[3,5])-fluidInput.PVTO_UNSAT(1,2:3)))<1e-7, ...
       'PVTO_UNSAT and saturated endpoint mismatch');
% Single-source PVT: PVTO_UNSAT is taken verbatim from the user file.
% The former NewOil_Fluids_Input.m override was removed.
% No interpolation or overwrite of user-entered PVTO_UNSAT is performed here.
fprintf('Stage 4: PVTO_UNSAT from user input: %d rows; upper P=%.2f kPa\n', ...
        size(fluidInput.PVTO_UNSAT,1),fluidInput.PVTO_UNSAT(end,1));
rhoSurface=fluidInput.DENSITY;
pvtw=[fluidInput.PVTW(1)/100,fluidInput.PVTW(2),fluidInput.PVTW(3)*100, ...
      fluidInput.PVTW(4),fluidInput.PVTW(5)*100];
pvto_sat=fluidInput.PVT6(:,[2,1,3,5]); pvto_sat(:,2)=pvto_sat(:,2)/100;
pvto_unsat=fluidInput.PVTO_UNSAT; pvto_unsat(:,1)=pvto_unsat(:,1)/100;
pvdg=fluidInput.PVT6(:,[1,4,6]); pvdg(:,1)=pvdg(:,1)/100;
swof=fluidInput.SWOF; sgof=fluidInput.SGOF;
fprintf('Stage 4: fluid data read: %s; Pb=%.4f bar, muO(Pb)=%.5f cP\n', ...
        pvtSourceFile, pvto_sat(end,2), pvto_sat(end,4));
