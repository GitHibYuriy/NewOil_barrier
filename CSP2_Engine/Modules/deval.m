
function [yq, yp] = deval(sol, xq, varargin)
% Octave compatibility for deval(ode45_solution, xq).
% Interpolates stored ODE solution using PCHIP.
% Intended for MRST EQUIL initialization.

    if ~isstruct(sol) || ~isfield(sol, 'x') || ~isfield(sol, 'y')
        error('deval: Expected ODE solution structure with x and y.');
    end

    x = sol.x(:);
    Y = sol.y;

    if size(Y, 2) == numel(x)
        % MATLAB/Octave solution layout: states x points
        Y = Y.';
    elseif size(Y, 1) ~= numel(x)
        error('deval: Unexpected dimensions of sol.y.');
    end

    [x, idx] = sort(x);
    Y = Y(idx, :);

    assert(all(diff(x) > 0), ...
        'deval: ODE solution coordinates must be unique.');

    xq = xq(:);

    if any(xq < x(1)) || any(xq > x(end))
        error('deval: Query outside the ODE integration interval.');
    end

    % Shape-preserving cubic interpolation
    V = interp1(x, Y, xq, 'pchip');

    % MATLAB deval returns states x query points
    yq = V.';

    if nargout > 1
        error('deval: Derivative output is not implemented.');
    end
end
