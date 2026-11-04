function q = NewOil_Fetkovich_Rate(a, pBoundary, dt)
% Explicit Fetkovich finite-aquifer recurrence; returns reservoir m3/s.
% Aquifer state a.pAquifer must only be updated AFTER step acceptance.
if ~a.enabled, q=0; return; end
assert(dt>0 && a.C>0 && a.J>0 && isfinite(pBoundary));
deltaWe = a.C*(a.pAquifer-pBoundary)*(-expm1(-a.J*dt/a.C));
q = max(0,deltaWe/dt); % aquifer influx only; leakage OFF
assert(isfinite(q));
end
