function [Gax,rock,cellDepth,op,geo]=CSP2_Grid(D)
% 2D R-Z tensor grid with exact cylindrical volumes and TPFA transmissibility.
% Layer index increases downwards. I index increases outwards.
Nr=D.grid.dimensions(1); Nz=D.grid.dimensions(3);
assert(D.grid.dimensions(2)==1,'CSP2 axisymmetric grid requires Nj=1');
dr=D.grid.dr_m(:)'; dz=D.grid.dz_m(:)';
poro=D.grid.poro_by_layer(:);
kh=D.grid.k_horizontal_mD_by_layer(:);
kv=D.grid.k_vertical_mD_by_layer(:);
if strcmp(D.grid.layer_order,'bottom_to_top')
 dz=fliplr(dz); poro=flipud(poro); kh=flipud(kh); kv=flipud(kv);
elseif ~strcmp(D.grid.layer_order,'top_to_bottom')
 error('Unknown grid.layer_order');
end
assert(numel(dr)==Nr && numel(dz)==Nz,'Grid dimension mismatch');
rEdge=[0,cumsum(dr)];zEdge=[0,cumsum(dz)];
G=tensorGrid(rEdge,zEdge);G=computeGeometry(G);
assert(G.cells.num==Nr*Nz);
Gax=G; rc=G.cells.centroids(:,1);
Gax.cells.volumes=G.cells.volumes.*(2*pi*rc);
radial=abs(G.faces.normals(:,1))>abs(G.faces.normals(:,2));
vertical=~radial;
Gax.faces.areas(radial)=G.faces.areas(radial).*2*pi.*G.faces.centroids(radial,1);
Gax.faces.areas(vertical)=G.faces.areas(vertical).*2*pi.*G.faces.centroids(vertical,1);
rock.poro=zeros(G.cells.num,1);rock.perm=zeros(G.cells.num,2);
cellDepth=zeros(G.cells.num,1);
for k=1:Nz
 c=(1:Nr)+(k-1)*Nr;
 rock.poro(c)=poro(k);
 rock.perm(c,1)=kh(k)*milli*darcy;
 rock.perm(c,2)=kv(k)*milli*darcy;
 cellDepth(c)=D.grid.top_layer_center_depth_m + ...
   (sum(dz(1:k-1)) + dz(k)/2 - dz(1)/2);
end
% Exact half transmissibilities: radial 2*pi*k*h/log(rface/rcenter)
% and vertical k*pi*(rout^2-rin^2)/distance.
cf=Gax.cells.faces(:,1);Th=zeros(numel(cf),1);
for c=1:G.cells.num
 i=mod(c-1,Nr)+1;k=floor((c-1)/Nr)+1;
 rows=Gax.cells.facePos(c):Gax.cells.facePos(c+1)-1;
 for q=rows
  f=cf(q);
  if radial(f)
   rf=G.faces.centroids(f,1); rcc=G.cells.centroids(c,1);
   if rf>0
    Th(q)=2*pi*rock.perm(c,1)*dz(k)/abs(log(rf/rcc));
   else
    Th(q)=0;
   end
  else
   dd=abs(G.faces.centroids(f,2)-G.cells.centroids(c,2));
   ann=pi*(rEdge(i+1)^2-rEdge(i)^2);
   Th(q)=rock.perm(c,2)*ann/dd;
  end
 end
end
internal=all(Gax.faces.neighbors~=0,2);
faces=find(internal);T=zeros(numel(faces),1);
for j=1:numel(faces)
 vals=Th(cf==faces(j));
 assert(numel(vals)==2);
 T(j)=1/sum(1./vals);
end
op=setupOperatorsTPFA(Gax,rock,'trans',T, ...
 'porv',Gax.cells.volumes.*rock.poro);
geo.rEdge=rEdge;geo.zEdge=zEdge;geo.dr=dr;geo.dz=dz;
fprintf('Grid: %d cells; PV=%.6f m3; outer radius=%.4f m\n', ...
 Gax.cells.num,sum(op.pv),rEdge(end));
end
