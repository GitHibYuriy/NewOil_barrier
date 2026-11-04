% STAGE 13: SAVE NUMERICAL DATA AND FIGURES
% ============================================================

fprintf('\n=== STAGE 13: SAVE RESULTS ===\n');

% Directory containing the checkpoint
saveDir13 = fileparts(checkpointFile11);

if ~exist(saveDir13, 'dir')
    mkdir(saveDir13);
end

% ------------------------------------------------------------
% 1. Save reservoir states and grid
% ------------------------------------------------------------

save('-mat7-binary', ...
     fullfile(saveDir13, 'reservoir_states.mat'), ...
     'state0', 'state11', 'Gdepth', 'Gax', 'rock', ...
     't11');

fprintf('Reservoir states saved.\n');

% ------------------------------------------------------------
% 2. Save production history
% ------------------------------------------------------------

save('-mat7-binary', ...
     fullfile(saveDir13, 'production_history.mat'), ...
     'time11', 'qO11', 'qW11', 'qG11', ...
     'bhp11', 'wcut11', 'gor11', ...
     'mode11', 'event11');

fprintf('Production history saved.\n');

% ------------------------------------------------------------
% 3. Save figures as PNG
% ------------------------------------------------------------

drawnow;

figNums13 = [31 32 33 34 35 36];

figNames13 = {
    '01_Production_rates.png'
    '02_Water_cut.png'
    '03_GOR.png'
    '04_Sw_initial.png'
    '05_Sw_final.png'
    '06_Delta_Sw.png'
};

for i13 = 1:numel(figNums13)

    fig13 = findall(0, 'type', 'figure', ...
                    'number', figNums13(i13));

    if ~isempty(fig13) && isgraphics(fig13(1))

        try
            drawnow();

            print(fig13(1), ...
                  fullfile(saveDir13, figNames13{i13}), ...
                  '-dpng', '-r200');

            fprintf('Saved: %s\n', figNames13{i13});

        catch err13
            fprintf('WARNING: Figure %d not saved: %s\n', ...
                    figNums13(i13), err13.message);
        end

    else
        fprintf('Figure %d not found; skipped.\n', ...
                figNums13(i13));
    end

end

fprintf('All available results saved in:\n%s\n', saveDir13);
fprintf('=== STAGE 13 COMPLETE ===\n');
