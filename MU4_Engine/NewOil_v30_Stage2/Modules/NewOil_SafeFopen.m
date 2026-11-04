function [fid, actualName] = NewOil_SafeFopen(targetName)
% Do not create numbered file copies: all outputs must remain in one directory.
[fid,msg] = fopen(targetName,'w');
actualName = targetName;
if fid < 0
    error('Cannot write %s: %s. Stop rather than scatter results.',targetName,msg);
end
end
