function F = griddedInterpolant(x, v, method, extrapolation)
% Octave compatibility for MRST EQUIL RSVD/PBVD/RVVD depth tables.
% Supported: one-dimensional grid, linear interpolation, nearest extrapolation.
% This file is local to the reservoir model; MRST installation is unchanged.
if nargin < 3 || isempty(method), method = 'linear'; end
if nargin < 4 || isempty(extrapolation), extrapolation = 'nearest'; end
if ~strcmpi(method,'linear') || ~strcmpi(extrapolation,'nearest')
    error('Local griddedInterpolant: only linear/nearest is supported.');
end
x = x(:); v = v(:);
if numel(x) ~= numel(v) || numel(x) < 2 || any(~isfinite(x)) || any(~isfinite(v))
    error('Local griddedInterpolant: invalid interpolation table.');
end
[x, ix] = sort(x); v = v(ix);
if any(diff(x) <= 0)
    error('Local griddedInterpolant: grid nodes must be distinct.');
end
F = @(z) interp1(x, v, min(max(z,x(1)),x(end)), 'linear');
end
