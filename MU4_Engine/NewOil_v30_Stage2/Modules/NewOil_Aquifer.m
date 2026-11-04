% v26: finite radial Fetkovich aquifer, parameters verified against CMG IMEX.
run(fullfile(inputDir, 'NewOil_Aquifer_Input.m'));
AQ_CT = struct();
AQ_CT.enabled = ENABLE_AQUIFER;
AQ_CT.method = 'FETKOVICH';
AQ_CT.cells = ((Nz-1)*Nr+(1:Nr))';
AQ_CT.area = pi*(rEdge(2:end).^2-rEdge(1:end-1).^2)';
AQ_CT.A = sum(AQ_CT.area);
AQ_CT.re = sqrt(AQ_CT.A/pi);
AQ_CT.ratio = AQ_RATIO;
AQ_CT.ra = AQ_CT.re*AQ_CT.ratio;
AQ_CT.angle = AQ_ANGLE;
AQ_CT.h = AQ_THICKNESS_M;
AQ_CT.phi = AQ_POROSITY;
AQ_CT.k = AQ_PERMEABILITY_MD*milli*darcy;
AQ_CT.mu = AQ_VISCOSITY_CP*centi*poise;
AQ_CT.ct = AQ_COMPRESSIBILITY_PER_PA;   % CMG total compressibility 1e-6 /kPa -> 1e-9 /Pa
AQ_CT.Vp = pi*(AQ_CT.ra^2-AQ_CT.re^2)*AQ_CT.h*AQ_CT.phi*AQ_CT.angle;
AQ_CT.C = AQ_CT.Vp*AQ_CT.ct;  % m3/Pa
AQ_CT.J = 2*pi*AQ_CT.k*AQ_CT.h*AQ_CT.angle / ...
    (AQ_CT.mu*(log(AQ_CT.ratio)-0.75)); % m3/(Pa*s)
AQ_CT.pInit = sum(state0.pressure(AQ_CT.cells).*AQ_CT.area)/AQ_CT.A;
AQ_CT.pAquifer = AQ_CT.pInit;
AQ_CT.cumulative = 0;
AQ_CT.Q = zeros(0,1); AQ_CT.dt = zeros(0,1);
assert(AQ_CT.C>0 && AQ_CT.J>0 && all(AQ_CT.area>0));
fprintf('\n=== CMG FETKOVICH AQUIFER ===\n');
fprintf('Area %.4f m2; re %.4f m; ra %.4f m; h %.4f m\n',AQ_CT.A,AQ_CT.re,AQ_CT.ra,AQ_CT.h);
fprintf('Pore volume %.6f m3; C %.9f m3/bar; J %.6f m3/(day*bar)\n', ...
    AQ_CT.Vp,AQ_CT.C*barsa,AQ_CT.J*day*barsa);
fprintf('Initial aquifer pressure %.6f bar; initial elastic potential %.4f m3\n', ...
    AQ_CT.pInit/barsa,AQ_CT.C*AQ_CT.pInit);
