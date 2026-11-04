% =========================================================================
% STAGE 5: Attach exact cylindrical transmissibilities to MRST AD operators
% =========================================================================
internal = all(Gax.faces.neighbors ~= 0, 2);
Tint = Tface(internal);

% Use the already validated axisymmetric pore volume.
porvAxis = Gax.cells.volumes .* rock.poro;

opExact = setupOperatorsTPFA(Gax, rock, ...
                            'trans', Tint, ...
                            'porv', porvAxis);

fprintf('\n=== Stage 5: MRST AD operator validation ===\n');
fprintf('Internal connections            : %d\n', numel(Tint));
fprintf('Operator connections            : %d\n', numel(opExact.T));
fprintf('Max |T_operator-T_exact|        : %.12e\n', max(abs(opExact.T-Tint)));
fprintf('Total axisymmetric pore volume  : %.12e m^3\n', sum(porvAxis));
fprintf('Operator pore volume total      : %.12e m^3\n', sum(opExact.pv));

assert(numel(opExact.T)==numel(Tint));
assert(max(abs(opExact.T-Tint)) < 1e-20);
assert(abs(sum(opExact.pv)-sum(porvAxis)) < 1e-10*max(1,sum(porvAxis)));

nZero = sum(opExact.T == 0);
fprintf('Zero internal transmissibilities: %d\n', nZero);
fprintf('Stage 5 operators connected successfully.\n');


