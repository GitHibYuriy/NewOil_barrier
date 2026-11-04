function CSP2_WriteDeck(D,path)
% Generated fluid/EQUIL deck. JSON in Input is the only authoritative PVT source.
% ECLIPSE METRIC: pressure bar, depths m, densities kg/m3, Rs sm3/sm3.
fid=fopen(path,'w');assert(fid>0,'Cannot create Eclipse deck');
cleanup=onCleanup(@()fclose(fid));
C=D.deck; dims=D.grid.dimensions; n=prod(dims);
fprintf(fid,'RUNSPEC\nTITLE\n%s\nDIMENS\n%d %d %d /\n',C.title,dims(1),dims(2),dims(3));
fprintf(fid,'OIL\nWATER\nGAS\nDISGAS\nMETRIC\nSTART\n%s /\n',C.start_date);
fprintf(fid,'TABDIMS\n%s /\nEQLDIMS\n%s /\n',sprintf('%d ',C.tabdims),sprintf('%d ',C.eqldims));
fprintf(fid,'GRID\nDX\n%d*%.12g /\nDY\n%d*%.12g /\nDZ\n%d*%.12g /\nTOPS\n%d*0 /\n',n,C.dummy_cell_width_m,n,C.dummy_cell_width_m,n,C.dummy_cell_width_m,n);
fprintf(fid,'PORO\n%d*%.12g /\nPERMX\n%d*%.12g /\nPERMY\n%d*%.12g /\nPERMZ\n%d*%.12g /\n',n,C.dummy_porosity,n,C.dummy_horizontal_perm_mD,n,C.dummy_horizontal_perm_mD,n,C.dummy_vertical_perm_mD);
fprintf(fid,'PROPS\n');
fprintf(fid,'ROCK\n%.12g %.12g /\n',D.rock.reference_pressure_kPa/100, D.rock.compressibility_per_kPa*100);
fprintf(fid,'DENSITY\n%.12g %.12g %.12g /\n',D.fluid.oil_density_kg_m3,D.fluid.water_density_kg_m3,D.fluid.gas_density_kg_m3);
fprintf(fid,'PVTW\n%.12g %.12g %.12g %.12g 0 /\n', ...
 D.fluid.water_p_ref_kPa/100,D.fluid.water_B_ref,D.fluid.water_compressibility_per_kPa*100,D.fluid.water_mu_cP);
P=D.fluid.PVT; co=D.fluid.oil_compressibility_per_kPa;
% PVTO: saturated (Rs,p,Bo,mu), followed by an undersaturated point.
% Initial PB=0 in CMG; include a zero-Rs branch by extrapolating first data row.
fprintf(fid,'PVTO\n');
Rs0=0; p0=P(1,1)/100; bo0=P(1,3);mu0=P(1,5);
writeBranch(fid,Rs0,p0,bo0,mu0,P(end,1)/100,co,C.pvto_pressure_extension_bar);
for j=1:size(P,1)
 writeBranch(fid,P(j,2),P(j,1)/100,P(j,3),P(j,5),P(end,1)/100,co,C.pvto_pressure_extension_bar);
end
fprintf(fid,'/\n');
fprintf(fid,'PVDG\n');
for j=1:size(P,1)
 fprintf(fid,'%.12g %.12g %.12g\n',P(j,1)/100,1/P(j,4),P(j,6));
end
fprintf(fid,'/\n');
fprintf(fid,'SWOF\n'); S=D.fluid.SWT;
for j=1:size(S,1)
 fprintf(fid,'%.12g %.12g %.12g %.12g\n',S(j,1),S(j,2),S(j,3),S(j,4)/100);
end
fprintf(fid,'/\n');
fprintf(fid,'SGOF\n'); L=D.fluid.SLT;
for j=size(L,1):-1:1
 fprintf(fid,'%.12g %.12g %.12g %.12g\n',1-L(j,1),L(j,2),L(j,3),L(j,4)/100);
end
fprintf(fid,'/\nSOLUTION\nEQUIL\n');
% ECLIPSE EQUIL: datum depth, datum pressure, WOC, Pcow at WOC,
% GOC, Pcog at GOC, live-oil equil flag, wet-gas equil flag, accuracy.
fprintf(fid,'%.12g %.12g %.12g 0 %.12g 0 0 0 %.0f /\n', ...
 D.initial.reference_depth_m,D.initial.reference_pressure_kPa/100, ...
 D.initial.WOC_depth_m,D.initial.GOC_depth_m,C.equil_accuracy);
% CMG PB=0: oil starts undersaturated with Rs=0. PBVD depth/pb in bar.
fprintf(fid,'PBVD\n%.12g 0\n%.12g 0 /\n', ...
 min(D.initial.GOC_depth_m-C.pbvd_extension_m,D.initial.reference_depth_m-C.pbvd_extension_m), ...
 max(D.initial.WOC_depth_m+C.pbvd_extension_m,D.initial.reference_depth_m+C.pbvd_extension_m));
fprintf(fid,'SCHEDULE\nEND\n');
end
function writeBranch(fid,rs,p,bo,mu,pMax,co,extension)
% Avoid repeated pressures in a PVTO branch.
pHigh=max(pMax+extension,p+extension);
bHigh=bo*exp(-co*(pHigh-p)*100);
fprintf(fid,'%.12g %.12g %.12g %.12g\n',rs,p,bo,mu);
fprintf(fid,'  %.12g %.12g %.12g /\n',pHigh,bHigh,mu);
end
