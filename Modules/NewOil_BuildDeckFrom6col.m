function outFile = NewOil_BuildDeckFrom6col(fluidData, initData, outFile, gridData)
% Convert validated NewOil fluidInput struct to ECLIPSE-compatible deck.
% Preserve non-fluid EQUIL/well schedule; generate grid/rock from editable input.
% NewOil's PVT6 and PVTO_UNSAT are project-specific, not Eclipse keywords.
assert(isstruct(fluidData), 'Pass fluidInput struct from NewOil_PVT_Tables.m');
A=fluidData.PVT6; U=fluidData.PVTO_UNSAT;
P=A(:,1)/100; Rs=A(:,2); Bo=A(:,3); Bg=A(:,4);
muO=A(:,5); muG=A(:,6); PU=U(:,1)/100;
assert(all(diff(P)>0) && all(diff(PU)>0));
assert(abs(P(end)-PU(1))<1e-7);
assert(abs(Bo(end)-U(1,2))<1e-7 && abs(muO(end)-U(1,3))<1e-7);
assert(all(all(U(:,2:3)>0)));
assert(any(abs(U(:,1)-max(U(:,1)))<1e-5), 'Missing upper PVT pressure node');
% Generate a self-contained MRST adapter deck from the editable Input files.
% No ECLIPSE template is read. The adapter is written under Results only.
assert(isstruct(gridData), 'Missing gridData');
Nr = numel(gridData.dr); Nz = numel(gridData.dz);
assert(numel(gridData.dtop)==Nr && Nr>0 && Nz>0);
assert(all(gridData.dr>0) && all(gridData.dz>0));
poro = zeros(1,Nr*Nz); kr=poro; kz=poro;
for k=1:Nz
 ix=(k-1)*Nr+(1:Nr);
 if k<gridData.lowerLayerFirst
  poro(ix)=gridData.poroUpper; kr(ix)=gridData.krUpper;
  kz(ix)=gridData.kzUpper*gridData.kvMultiplier;
 else
  poro(ix)=gridData.poroLower; kr(ix)=gridData.krLower;
  kz(ix)=gridData.kzLower*gridData.kvMultiplier;
 end
end
if gridData.barrierEnabled
 for k=gridData.barrierK(1):gridData.barrierK(2)
  ix=(k-1)*Nr+(gridData.barrierI(1):gridData.barrierI(2));
  kr(ix)=gridData.barrierKr; kz(ix)=gridData.barrierKz;
 end
end
% ROCK compressibility parameters are exposed in initialization input.
assert(exist('initData','var') && isstruct(initData), 'Missing initialization data');
assert(numel(initData.equil)==7, 'EQUIL requires seven explicit entries');
assert(numel(initData.rsvdDepths)==2 && all(isfinite(initData.rsvdDepths)));
src=sprintf(['RUNSPEC\nTITLE\nNewOil generated MRST adapter deck\n', ...
 'DIMENS\n%d 1 %d /\nRADIAL\nOIL\nWATER\nGAS\nDISGAS\nMETRIC\n', ...
 'START\n1 JAN 2000 /\nWELLDIMS\n1 %d 1 1 /\n', ...
 'TABDIMS\n1 1 21 30 1 20 /\nEQLDIMS\n1 1 2 1 1 /\n', ...
 'GRID\nINRAD\n%.12g /\nDRV\n'], Nr, Nz, Nz, gridData.rw);
src=[src,sprintf('%.12g ',gridData.dr),sprintf('/\nDTHETAV\n360 /\nDZV\n')];
src=[src,sprintf('%.12g ',gridData.dz),sprintf('/\nTOPS\n')];
src=[src,sprintf('%.12g ',gridData.dtop),sprintf('/\n')];
src=[src,sprintf('PORO\n'),sprintf('%.12g ',poro),sprintf('/\n')];
src=[src,sprintf('PERMR\n'),sprintf('%.12g ',kr),sprintf('/\n')];
src=[src,sprintf('PERMTHT\n'),sprintf('%.12g ',kr),sprintf('/\n')];
src=[src,sprintf('PERMZ\n'),sprintf('%.12g ',kz),sprintf('/\n')];
src=[src,sprintf('PROPS\nROCK\n%.12g %.12g /\n', ...
 initData.rockPressureBar,initData.rockCompressibilityPerBar)];
% Keep ROCK from template; replace all fluid PVT and relative permeability.
F=fluidData;
txt=sprintf('DENSITY\n%.12g %.12g %.12g /\n',F.DENSITY);
w=F.PVTW;
txt=[txt,sprintf('PVTW\n%.12g %.12g %.12g %.12g %.12g /\n', ...
                  w(1)/100,w(2),w(3)*100,w(4),w(5)*100)];
txt=[txt,sprintf('PVTO\n')];
% Each Rs branch has a saturated point and a strictly increasing P tail.
% At P<=Pb, use source table points (original six-column algorithm).
% At P>Pb, use the calibrated SR3-anchored linear undersaturated tail.
% Scaling by the branch bubblepoint properties preserves the original
% saturated branch behavior and continuity at Pb.
for j=1:numel(P)
    txt=[txt,sprintf('%.12g %.12g %.12g %.12g\n',Rs(j),P(j),Bo(j),muO(j))];
    for i=j+1:numel(P)
        txt=[txt,sprintf(' %.12g %.12g %.12g\n',P(i),Bo(i),muO(i))];
    end
    for i=2:numel(PU)
        bval=Bo(end)*U(i,2)/U(1,2);
        mval=muO(end)*U(i,3)/U(1,3);
        txt=[txt,sprintf(' %.12g %.12g %.12g\n',PU(i),bval,mval)];
    end
    txt=[txt,sprintf('/\n')];
end
txt=[txt,sprintf('/\nPVDG\n')];
for i=1:numel(P)
    txt=[txt,sprintf('%.12g %.12g %.12g\n',P(i),Bg(i),muG(i))];
end
txt=[txt,sprintf('/\nSWOF\n')];
for i=1:size(F.SWOF,1)
    txt=[txt,sprintf('%.12g %.12g %.12g %.12g\n',F.SWOF(i,:))];
end
txt=[txt,sprintf('/\nSGOF\n')];
for i=1:size(F.SGOF,1)
    txt=[txt,sprintf('%.12g %.12g %.12g %.12g\n',F.SGOF(i,:))];
end
txt=[txt,sprintf('/\n')];
src=[src,txt];
% Explicit equilibrium and solution gas depth table: only the Input
% initialization file is authoritative for these values.
equilText=sprintf('%.12g %.12g %.12g %.12g %.12g %.12g %.12g 1* 1* 2* 1* /',initData.equil(1:7));
src=[src,sprintf('SOLUTION\nEQUIL\n%s\n',equilText)];
rsb=Rs(end);
src=[src,sprintf('RSVD\n%.12g %.12g\n%.12g %.12g /\n', ...
 initData.rsvdDepths(1),rsb,initData.rsvdDepths(2),rsb)];
src=[src,sprintf('SUMMARY\nALL\nSCHEDULE\nEND\n')];
fid=fopen(outFile,'w'); assert(fid>=0,'Cannot write generated deck');
fwrite(fid,src); fclose(fid);
fprintf('Generated MRST deck from ONE fluid source: Pb=%.4f bar, Rsb=%.6f\n',P(end),rsb);
end
