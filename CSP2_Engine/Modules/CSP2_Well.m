function [W,meta]=CSP2_Well(D,G,rock,depth,geo)
Nr=D.grid.dimensions(1); Nz=D.grid.dimensions(3);
ks=D.well.perforation_layers(:);
if strcmp(D.well.perforation_layer_order,'bottom_to_top')
 ks=Nz+1-ks;
elseif ~strcmp(D.well.perforation_layer_order,'top_to_bottom')
 error('Unknown well.perforation_layer_order');
end
assert(all(ks>=1 & ks<=Nz),'Perforation layers out of range');
cells=1+(ks-1)*Nr;
% CMG *GEOMETRY *K rw geofac wfrac skin: geofac=0.5.
% WI is an explicit engineering approximation pending CMG WI comparison.
rw=D.well.radius_m; geofac=D.well.geometric_factor;skin=D.well.skin;
WI=zeros(numel(ks),1);
for j=1:numel(ks)
 k=ks(j);rEq=geofac*geo.rEdge(2);
 assert(rEq>rw,'Well radius exceeds equivalent block radius');
 WI(j)=2*pi*rock.perm(cells(j),1)*geo.dz(k)/(log(rEq/rw)+skin);
end
gravity reset on; gravity([0 D.model.gravity_m_s2]);
W=addWell([],G,rock,cells,'Name',D.well.name, ...
 'Type','orat','Val',-D.well.oil_rate_schedule_days_m3_day(1,2)*meter^3/day, ...
 'WI',WI,'Radius',rw,'Sign',-1,'refDepth',0,'compi',[0 1 0]);
W.refDepth=depth(cells(1));W.dZ=depth(cells)-W.refDepth;
% Minimum BHP constraint; explicit switching implemented in CSP2_Run.
meta.cells=cells;meta.WI_m3=WI;meta.refDepth_m=W.refDepth;
fprintf('Well perforations K=%d,%d; WI %.6g %.6g m3\n',ks(1),ks(2),WI(1),WI(2));
end
