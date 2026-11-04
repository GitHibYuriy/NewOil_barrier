function out = NewOil_BalanceReport(st, model, fluid, rock, st0, aq, Np, Wp, Gp, timeD, resultDir)
% CMG-style inventory calculated from actual MRST grid/state/PVT.
% Units: M rm3 = 1e3 reservoir m3, M m3 = 1e3 surface m3,
% MM m3 = 1e6 surface m3, kPa, %. No IMEX inventory constants used.
pv = model.operators.pv(:); p=st.pressure(:); n=numel(pv);
assert(numel(p)==n && numel(rock.poro)==n);
ph=model.getPhaseNames(); iw=find(ph=='W');io=find(ph=='O');ig=find(ph=='G');
assert(numel(iw)==1 && numel(io)==1 && numel(ig)==1);
sw=st.s(:,iw); so=st.s(:,io); sg=st.s(:,ig);
assert(all(isfinite(p)) && all(isfinite(st.s(:))));
% Black-oil bX are inverse FVF: surface volume / reservoir volume.
bw = fluid.bW(p);

if isfield(st,'rs')
    rs = st.rs(:);
else
    rs = zeros(n,1);
end

bo = fluid.bO(p,rs,false(n,1));

bg = fluid.bG(p);
if isscalar(bw),bw=repmat(bw,n,1);end
if isscalar(bo),bo=repmat(bo,n,1);end
if isscalar(bg),bg=repmat(bg,n,1);end
bw=bw(:);bo=bo(:);bg=bg(:);
assert(all(isfinite([bw;bo;bg])) && all([bw;bo;bg]>0));
pvHC=pv.*(so+sg); volO=pv.*so;volW=pv.*sw;volG=pv.*sg;
sto=sum(volO.*bo);gasFree=sum(volG.*bg);gasDiss=sum(volO.*bo.*rs);
% Mobile oil approximation from SWOF endpoint Sor=1-Sw(krOW=0)=0.34.
% This is a relperm-endpoint estimate, NOT an exact CMG mobile-STO definition.
Sor=0.34;
mobileSTO=sum(pv.*max(so-Sor,0).*bo);
baseSTO=NaN; baseMobileSTO=NaN; baseGas=NaN; baseWater=NaN;
if timeD>0
 p0=st0.pressure(:);rs0=zeros(n,1);
 if isfield(st0,'rs'),rs0=st0.rs(:);end
 try,b0=fluid.bO(p0,rs0,false(n,1));
 catch,b0=fluid.bO(p0,rs0);end
 if isscalar(b0),b0=repmat(b0,n,1);end
 baseSTO=sum(pv.*st0.s(:,io).*b0(:));
 baseMobileSTO=sum(pv.*max(st0.s(:,io)-Sor,0).*b0(:));
 try,bg0=fluid.bG(p0);catch,bg0=bg;end
 if isscalar(bg0),bg0=repmat(bg0,n,1);end
 baseGas=sum(pv.*st0.s(:,ig).*bg0(:))+sum(pv.*st0.s(:,io).*b0(:).*rs0);
 try,bw0=fluid.bW(p0);catch,bw0=bw;end
 if isscalar(bw0),bw0=repmat(bw0,n,1);end
 baseWater=sum(pv.*st0.s(:,iw).*bw0(:));
end
out=struct('time_d',timeD,'pore_volume_m3',sum(pv), ...
 'hc_pore_volume_m3',sum(pvHC),'stock_tank_oil_m3',sto, ...
 'mobile_sto_est_m3',mobileSTO,'total_gas_sm3',gasFree+gasDiss, ...
 'free_gas_sm3',gasFree,'water_surface_m3',sum(volW.*bw), ...
 'reservoir_oil_m3',sum(volO),'reservoir_gas_m3',sum(volG), ...
 'reservoir_water_m3',sum(volW),'water_influx_m3',aq.cumulative, ...
 'pressure_pv_kpa',sum(pv.*p)/sum(pv)/1000, ...
 'pressure_hc_kpa',sum(pvHC.*p)/max(sum(pvHC),eps)/1000, ...
 'oil_saturation_pct',100*sum(volO)/sum(pv), ...
 'gas_saturation_pct',100*sum(volG)/sum(pv), ...
 'water_saturation_pct',100*sum(volW)/sum(pv), ...
 'cumulative_oil_sm3',Np,'cumulative_water_sm3',Wp, ...
 'cumulative_gas_sm3',Gp);
if timeD==0,label='INITIAL';else,label='FINAL';end
lines={};
lines{end+1}=sprintf('=== MRST %s MATERIAL BALANCE at t=%.3f d ===',label,timeD);
lines{end+1}=sprintf('Total Pore Volume      M rm3    %14.6f',sum(pv)/1e3);
lines{end+1}=sprintf('HC. Pore Volume        M rm3    %14.6f',sum(pvHC)/1e3);
lines{end+1}='Fluids in Place';
lines{end+1}=sprintf('  Stock Tank Oil       M m3     %14.6f',sto/1e3);
lines{end+1}=sprintf('  Mobile STO (est.)    M m3     %14.6f',mobileSTO/1e3);
lines{end+1}=sprintf('  Total Gas            MM m3    %14.6f',(gasFree+gasDiss)/1e6);
lines{end+1}=sprintf('  Free Gas             MM m3    %14.6f',gasFree/1e6);
lines{end+1}=sprintf('  Water                M m3     %14.6f',sum(volW.*bw)/1e3);
lines{end+1}=sprintf('  Reservoir Oil        M rm3    %14.6f',sum(volO)/1e3);
lines{end+1}=sprintf('  Reservoir Gas        M rm3    %14.6f',sum(volG)/1e3);
lines{end+1}=sprintf('  Reservoir Water      M rm3    %14.6f',sum(volW)/1e3);
lines{end+1}=sprintf('  Water Influx         M m3     %14.6f',aq.cumulative/1e3);
lines{end+1}='Average Pressure';
lines{end+1}=sprintf('  Total Pore Volume    kPa      %14.6f',out.pressure_pv_kpa);
lines{end+1}=sprintf('  HC. Pore Volume      kPa      %14.6f',out.pressure_hc_kpa);
lines{end+1}='Average Saturation %';
lines{end+1}=sprintf('  Oil                           %14.6f',out.oil_saturation_pct);
lines{end+1}=sprintf('  Gas                           %14.6f',out.gas_saturation_pct);
lines{end+1}=sprintf('  Water                         %14.6f',out.water_saturation_pct);
lines{end+1}='Percentage Recovery';
if timeD==0
 lines{end+1}='  Stock Tank Oil                   0.000000';
 lines{end+1}='  STO as a % of Mobile Oil         0.000000';
 lines{end+1}='  Total Gas                       0.000000';
 lines{end+1}='  Water                           0.000000';
else
 lines{end+1}=sprintf('  Stock Tank Oil               %14.6f',100*Np/max(baseSTO,eps));
 lines{end+1}=sprintf('  STO as a %% of Mobile Oil     %14.6f',100*Np/max(baseMobileSTO,eps));
 lines{end+1}=sprintf('  Total Gas                    %14.6f',100*Gp/max(baseGas,eps));
 lines{end+1}=sprintf('  Water                        %14.6f',100*Wp/max(baseWater,eps));
end
lines{end+1}='Cumulative Injection';
lines{end+1}='  Oil              M m3          0.000000';
lines{end+1}='  Gas              MM m3         0.000000';
lines{end+1}=sprintf('  Water            M m3     %14.6f',aq.cumulative/1e3);
lines{end+1}='Cumulative Production';
lines{end+1}=sprintf('  Oil              M m3     %14.6f',Np/1e3);
lines{end+1}=sprintf('  Gas              MM m3    %14.6f',Gp/1e6);
lines{end+1}=sprintf('  Water            M m3     %14.6f',Wp/1e3);
for j=1:numel(lines),fprintf('%s\n',lines{j});end
if exist(resultDir,'dir')~=7,mkdir(resultDir);end
filename=fullfile(resultDir,sprintf('material_balance_%s.txt',lower(label)));
fid=fopen(filename,'w');
if fid>=0
 for j=1:numel(lines),fprintf(fid,'%s\n',lines{j});end
 fclose(fid);
else,warning('Cannot save material balance report: %s',filename);end
end
