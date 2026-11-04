% Load editable geometry and rock inputs from sibling Input directory.
_gridInputFile = fullfile(fileparts(mfilename('fullpath')), '..', 'Input', 'NewOil_Grid_Input.m');
assert(exist(_gridInputFile, 'file') == 2, 'Missing NewOil_Grid_Input.m');
run(_gridInputFile);
Nr = numel(dr); Nz = numel(dz);
assert(numel(dtop) == Nr, 'DTOP count must match radial cell count');
assert(all(dr > 0) && all(dz > 0) && rw > 0, 'Grid dimensions must be positive');
assert(LOWER_LAYER_FIRST >= 2 && LOWER_LAYER_FIRST <= Nz, 'Invalid LOWER_LAYER_FIRST');
assert(PORO_UPPER > 0 && PORO_UPPER < 1 && PORO_LOWER > 0 && PORO_LOWER < 1, 'Invalid porosity');
assert(all([KR_UPPER_MD KR_LOWER_MD KZ_UPPER_MD KZ_LOWER_MD] >= 0), 'Negative permeability');
assert(KV_MULTIPLIER > 0, 'KV_MULTIPLIER must be positive');
rEdge = [rw, rw + cumsum(dr)];
zEdge = [0, cumsum(dz)];

assert(Nr >= 1); assert(Nz == 32);


G = tensorGrid(rEdge, zEdge);
G = computeGeometry(G);
assert(G.cells.num == Nr*Nz);

% Absolute depth of every cell center. Depth is positive downward.
% We keep the orthogonal computational grid unchanged so that the exact
% radial/vertical transmissibilities remain those already validated.
cellDepth = zeros(G.cells.num,1);
zMid = 0.5*(zEdge(1:end-1) + zEdge(2:end));
for kk = 1:Nz
    cells = (1:Nr) + (kk-1)*Nr;
    cellDepth(cells) = dtop(:) + zMid(kk);
end

% Separate plotting grid with physical depth as its vertical coordinate.
% It is for visualization only; G/Gax remain the flow-discretization grid.
Gdepth = G;
% DTOP is defined per radial CELL , not per radial.
% For visualization, assign the nearest cell's DTOP to each node column.
dtopNode = [dtop(1), 0.5*(dtop(1:end-1)+dtop(2:end)), dtop(end)];
Gdepth.nodes.coords(:,2) = interp1(rEdge, dtopNode, G.nodes.coords(:,1), 'linear') + G.nodes.coords(:,2);
Gdepth = computeGeometry(Gdepth);

Gax = G;
rc = G.cells.centroids(:,1);
Gax.cells.volumes = G.cells.volumes .* (2*pi*rc);

nx = abs(G.faces.normals(:,1));
nz = abs(G.faces.normals(:,2));
radialFace = nx > nz;
verticalFace = nz > nx;

rf = G.faces.centroids(radialFace,1);
Gax.faces.areas(radialFace) = G.faces.areas(radialFace).*2*pi.*rf;
rf = G.faces.centroids(verticalFace,1);
Gax.faces.areas(verticalFace) = G.faces.areas(verticalFace).*2*pi.*rf;

% Rock properties from editable input, grouped by layer.
rock.poro = zeros(Gax.cells.num,1);
krCell = zeros(Gax.cells.num,1);
kzCell = zeros(Gax.cells.num,1);
for kk = 1:Nz
    cells = (1:Nr) + (kk-1)*Nr;
    if kk < LOWER_LAYER_FIRST
        rock.poro(cells) = PORO_UPPER;
        krCell(cells) = KR_UPPER_MD;
        kzCell(cells) = KZ_UPPER_MD;
    else
        rock.poro(cells) = PORO_LOWER;
        krCell(cells) = KR_LOWER_MD;
        kzCell(cells) = KZ_LOWER_MD;
    end
end
% Optional barrier: override directional permeability BEFORE computing Th/Tface.
assert(isscalar(BARRIER_ENABLED) && (BARRIER_ENABLED == 0 || BARRIER_ENABLED == 1), ...
       'BARRIER_ENABLED must be true or false');
barrierCells = [];
if BARRIER_ENABLED
    bounds = [BARRIER_I; BARRIER_J; BARRIER_K];
    assert(isequal(size(bounds), [3 2]) && all(isfinite(bounds(:))) && ...
           all(bounds(:) == floor(bounds(:))) && all(bounds(:,1) >= 1) && ...
           all(bounds(:,2) >= bounds(:,1)), 'Invalid barrier I/J/K bounds');
    assert(BARRIER_I(2) <= Nr && isequal(BARRIER_J, [1 1]) && ...
           BARRIER_K(2) <= Nz, 'Barrier I/J/K outside grid (J must equal 1)');
    assert(all(isfinite([BARRIER_KI_MD BARRIER_KJ_MD BARRIER_KK_MD])) && ...
           all([BARRIER_KI_MD BARRIER_KJ_MD BARRIER_KK_MD] >= 0), ...
           'Barrier permeability must be finite and nonnegative');
    [barI, barK] = ndgrid(BARRIER_I(1):BARRIER_I(2), ...
                          BARRIER_K(1):BARRIER_K(2));
    barrierCells = barI(:) + (barK(:)-1)*Nr;
    krCell(barrierCells) = BARRIER_KI_MD;
    kzCell(barrierCells) = BARRIER_KK_MD / KV_MULTIPLIER;
end
rock.perm = [krCell, KV_MULTIPLIER*kzCell].*milli*darcy;
% KJ is retained as input for a future 3D model; not used by this 2D grid.
fprintf('Barrier enabled: %d; affected cells: %d\n', BARRIER_ENABLED, numel(barrierCells));
if BARRIER_ENABLED
    fprintf('  I=%d:%d J=1 K=%d:%d; KI/KJ/KK=%.6g/%.6g/%.6g mD\n', ...
        BARRIER_I(1), BARRIER_I(2), BARRIER_K(1), BARRIER_K(2), ...
        BARRIER_KI_MD, BARRIER_KJ_MD, BARRIER_KK_MD);
end
fprintf('Vertical K multiplier: %.6g\n',KV_MULTIPLIER);

% Exact axisymmetric half-transmissibilities in radial and vertical directions.
cf = Gax.cells.faces(:,1);
Th = zeros(size(cf));
for c = 1:Gax.cells.num
    ii = mod(c-1,Nr)+1;
    kk = floor((c-1)/Nr)+1;
    rci = G.cells.centroids(c,1);
    Aann = pi*(rEdge(ii+1)^2-rEdge(ii)^2);
    rows = Gax.cells.facePos(c):Gax.cells.facePos(c+1)-1;
    for q = rows
        f = cf(q);
        if radialFace(f)
            rf = G.faces.centroids(f,1);
            if rock.perm(c,1) == 0
                Th(q) = 0;
            else
                Th(q) = 2*pi*rock.perm(c,1)*dz(kk)/abs(log(rf/rci));
            end
        else
            d = abs(G.faces.centroids(f,2)-G.cells.centroids(c,2));
            if rock.perm(c,2) == 0
                Th(q) = 0;
            else
                Th(q) = rock.perm(c,2)*Aann/d;
            end
        end
    end
end

% Full internal-face transmissibilities, with zero-permeability handled explicitly.
Tface = nan(Gax.faces.num,1);
for f = 1:Gax.faces.num
    ix = find(cf == f);
    if numel(ix) == 2
        if any(Th(ix) == 0)
            Tface(f) = 0;
        else
            Tface(f) = 1/sum(1./Th(ix));
        end
    end
end

% Validation: first radial connection, cells 1-2.
f12 = find(Gax.faces.neighbors(:,1)==1 & Gax.faces.neighbors(:,2)==2);
if isempty(f12)
    f12 = find(Gax.faces.neighbors(:,1)==2 & Gax.faces.neighbors(:,2)==1);
end
ix12 = find(cf == f12);

r1 = G.cells.centroids(1,1);
r2 = G.cells.centroids(2,1);
rf12 = G.faces.centroids(f12,1);
k1 = rock.perm(1,1);
k2 = rock.perm(2,1);
h1 = dz(1);

T1_exact = 2*pi*k1*h1/abs(log(rf12/r1));
T2_exact = 2*pi*k2*h1/abs(log(r2/rf12));
T12_exact = 1/(1/T1_exact + 1/T2_exact);
T12_model = Tface(f12);

V1_exact = pi*(rEdge(2)^2-rEdge(1)^2)*dz(1);
V1_model = Gax.cells.volumes(1);

fprintf('\n=== NewOil radial-grid validation ===\n');
fprintf('Cells             : %d\n', Gax.cells.num);
fprintf('Grid              : %d radial x %d layers\n', Nr, Nz);
fprintf('Outer radius      : %.3f m\n', rEdge(end));
fprintf('Total volume      : %.6e m^3\n', sum(Gax.cells.volumes));
fprintf('\nCell 1 volume:\n');
fprintf('  model           : %.12e m^3\n', V1_model);
fprintf('  exact           : %.12e m^3\n', V1_exact);
fprintf('  relative error  : %.6e %%\n', 100*(V1_model/V1_exact-1));
fprintf('\nRadial connection cell 1 <-> cell 2:\n');
fprintf('  face number     : %d\n', f12);
fprintf('  r1 / rf / r2    : %.6f / %.6f / %.6f m\n', r1, rf12, r2);
fprintf('  T1 exact/model  : %.12e / %.12e\n', T1_exact, Th(ix12(1)));
fprintf('  T2 exact/model  : %.12e / %.12e\n', T2_exact, Th(ix12(2)));
fprintf('  T12 model       : %.12e\n', T12_model);
fprintf('  T12 exact       : %.12e\n', T12_exact);
fprintf('  relative error  : %.6e %%\n', 100*(T12_model/T12_exact-1));
% Validation of three characteristic vertical connections.
pairs = [1 48; 1364 1411; 1374 1421];
pairNames = {'vertical pair 1', 'vertical pair 2', 'vertical pair 3'};
fprintf('\nVertical transmissibility validation:\n');
for ip = 1:3
    ca=pairs(ip,1); cb=pairs(ip,2);
    fa=Gax.cells.faces(Gax.cells.facePos(ca):Gax.cells.facePos(ca+1)-1,1);
    fb=Gax.cells.faces(Gax.cells.facePos(cb):Gax.cells.facePos(cb+1)-1,1);
    f=intersect(fa,fb);
    ia=mod(ca-1,Nr)+1; ka=floor((ca-1)/Nr)+1;
    ib=mod(cb-1,Nr)+1; kb=floor((cb-1)/Nr)+1;
    Aa=pi*(rEdge(ia+1)^2-rEdge(ia)^2);
    Ab=pi*(rEdge(ib+1)^2-rEdge(ib)^2);
    kza=rock.perm(ca,2); kzb=rock.perm(cb,2);
    if kza==0, Ta=0; else, Ta=kza*Aa/(dz(ka)/2); end
    if kzb==0, Tb=0; else, Tb=kzb*Ab/(dz(kb)/2); end
    if Ta==0 || Tb==0, Texact=0; else, Texact=1/(1/Ta+1/Tb); end
    Tmodel=Tface(f);
    if Texact==0, relerr=double(Tmodel~=0)*Inf; if Tmodel==0, relerr=0; end
    else, relerr=abs(Tmodel-Texact)/Texact*100; end
    fprintf('  %s, cells %d <-> %d:\n',pairNames{ip},ca,cb);
    fprintf('    T model = %.12e\n',Tmodel);
    fprintf('    T exact = %.12e\n',Texact);
    fprintf('    relative error = %.6e %%\n',relerr);
end

fprintf('\nPermeability zones:\n');

fprintf('  Base radial Kr   : %.6g / %.6g mD (upper/lower)\n', KR_UPPER_MD, KR_LOWER_MD);
fprintf('  Base vertical Kz : %.6g / %.6g mD (upper/lower)\n', KV_MULTIPLIER*KZ_UPPER_MD, KV_MULTIPLIER*KZ_LOWER_MD);

fprintf('  Actual Kr min/max: %.6g / %.6g mD\n', min(rock.perm(:,1))/(milli*darcy), max(rock.perm(:,1))/(milli*darcy));
fprintf('  Actual Kz min/max: %.6g / %.6g mD\n', min(rock.perm(:,2))/(milli*darcy), max(rock.perm(:,2))/(milli*darcy));

if BARRIER_ENABLED
    fprintf('\nBarrier permeability:\n');
    fprintf('  Barrier cells    : %d\n', numel(barrierCells));
    fprintf('  Barrier Kr       : %.6g mD\n', rock.perm(barrierCells(1),1)/(milli*darcy));
    fprintf('  Barrier Kz       : %.6g mD\n', rock.perm(barrierCells(1),2)/(milli*darcy));
end

fprintf('\nDepth geometry:\n');
fprintf('  DTOP min/max    : %.2f / %.2f m\n', min(dtop), max(dtop));
fprintf('  Cell depth min  : %.2f m\n', min(cellDepth));
fprintf('  Cell depth max  : %.2f m\n', max(cellDepth));

% Visualization of the physical R-depth section.
% [plots disabled] figure;
% [plots disabled] plotGrid(Gdepth, 'FaceColor', 'none');
% plotting axes disabled
% [plots disabled] xlabel('Radius, m');
% [plots disabled] ylabel('Depth, m');
% [plots disabled] title('NewOil radial grid with CMG DTOP');
% [plots disabled] axis tight;

% [plots disabled] figure;
% [plots disabled] plotGrid(Gdepth, 'FaceColor', 'none');
% plotting axes disabled
% [plots disabled] xlabel('Radius, m');
% [plots disabled] ylabel('Depth, m');
% [plots disabled] title('NewOil near-well grid with CMG DTOP');
% [plots disabled] axis tight;
% xlim disabled

fprintf('\nStage 3 completed successfully.\n');


