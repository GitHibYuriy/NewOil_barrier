classdef NewOil_FetkovichModel < GenericBlackOilModel
    % Fully implicit Fetkovich aquifer influx coupled to the AD water balance.
    % Aquifer pressure is held fixed during each nonlinear timestep.
    properties
        aquifer
        aquiferDt
    end

    methods
        function model = NewOil_FetkovichModel(G, rock, fluid, varargin)
            model@GenericBlackOilModel(G, rock, fluid, varargin{:});
            model.aquifer = struct('enabled', false);
            model.aquiferDt = 0;
        end

        function [eqs, state, src] = addBoundaryConditionsAndSources(model, eqs, names, types, state, ...
                p, s, mob, rho, dissolved, components, forces)
            [eqs, state, src] = addBoundaryConditionsAndSources@GenericBlackOilModel( ...
                model, eqs, names, types, state, p, s, mob, rho, dissolved, components, forces);

            a = model.aquifer;
            if ~a.enabled
                return;
            end

            dt = model.aquiferDt;
            assert(dt > 0 && a.C > 0 && a.J > 0, 'Invalid implicit aquifer parameters');
            iw = find(strcmpi(names, 'water'), 1);
            assert(~isempty(iw) && strcmpi(types{iw}, 'cell'), 'Water balance not found');

            cells = a.cells(:);
            w = a.area(:)/a.A;
            assert(numel(cells) == numel(w) && abs(sum(w) - 1) < 1e-10, ...
                   'Invalid aquifer boundary weights');

            % Use the same reference pressure as the aquifer-history update.
            % state.pressure is an AD variable during nonlinear iterations.
            pRef = state.pressure;
            pb = sum(pRef(cells).*w);
            dp = a.pAquifer - pb;

            if isa(dp, 'ADI')
                dpval = dp.val;
            else
                dpval = dp;
            end
            % No backflow, matching the existing Fetkovich implementation.
            if dpval <= 0
                return;
            end

            factor = a.C*(-expm1(-a.J*dt/a.C))/dt;
            q = factor*dp;  % Reservoir-volume influx [m^3/s], AD variable.

            % Add influx as water mass source to the conservation equation.
            % The first phase density must be water for this model setup.
            qmass = q.*w.*rho{1}(cells);
            eqs{iw}(cells) = eqs{iw}(cells) - qmass;
        end
    end
end
