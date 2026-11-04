function NewOil_ModelParametersReport(outputDir, fluidInput, rEdge, barrierEnabled, barrierI, barrierK, rock, milliDarcy, initialPressure, initialRefDepth, owc)
fileName=fullfile(outputDir,'00_Model_Parameters.txt');
[fid,msg]=fopen(fileName,'w');
if fid<0, warning('Model report unavailable: %s',msg); return; end
fprintf(fid,'MODEL PARAMETERS\n');
fprintf(fid,'Initial pressure (kPa): %.9f\n',initialPressure);
fprintf(fid,'Initial reference depth (m): %.9f\n',initialRefDepth);
fprintf(fid,'Oil-water contact OWC (m): %.9f\n',owc);
A=fluidInput.PVT6;
fprintf(fid,'Bubble-point pressure (kPa): %.9f\n',A(end,1));
fprintf(fid,'Oil Bo at Pb (rm3/Sm3): %.9f\n',A(end,3));
fprintf(fid,'Oil viscosity at Pb (cP): %.9f\n',A(end,5));
fprintf(fid,'Solution GOR at Pb (Sm3/Sm3): %.9f\n',A(end,2));
fprintf(fid,'Barrier enabled: %d\n',barrierEnabled);
if barrierEnabled
 fprintf(fid,'Barrier I: %d:%d; K: %d:%d\n',barrierI(1),barrierI(2),barrierK(1),barrierK(2));
 fprintf(fid,'Barrier outer radius (m): %.9f\n',rEdge(barrierI(2)+1));
end
fclose(fid);
fprintf('Model parameters saved: %s\n',fileName);
end
