% STAGE 12: AUTOMATIC RESULTS AND PLOTS
% ============================================================

fprintf('\n=== STAGE 12: RESULTS AND PLOTS ===\n');

% --- Time in days ---
tPlot = time11(:);

% --- Production rates ---
QoPlot = qO11(:);
QwPlot = qW11(:);
QLPlot = QoPlot + QwPlot;

% --- Water cut and gas-oil ratio ---
WCPlot  = wcut11(:);
GORPlot = gor11(:);

% --- Check vector lengths ---
nPlot = numel(tPlot);

assert(numel(QoPlot) == nPlot, 'Qo length mismatch');
assert(numel(QwPlot) == nPlot, 'Qw length mismatch');
assert(numel(WCPlot) == nPlot, 'WCUT length mismatch');
assert(numel(GORPlot) == nPlot, 'GOR length mismatch');

% ============================================================
% FIGURE 1: LIQUID, OIL AND WATER RATES
% ============================================================

figure(31); clf;

plot(tPlot, QLPlot, 'k-', 'LineWidth', 1.8);
hold on;
plot(tPlot, QoPlot, 'g-', 'LineWidth', 1.6);
plot(tPlot, QwPlot, 'b-', 'LineWidth', 1.6);
hold off;

grid on;
xlabel('Time, days');
ylabel('Production rate, m3/day');
title('Liquid, oil and water production rates');

legend('Liquid', 'Oil', 'Water', 'location', 'best');

% ============================================================
% FIGURE 2: WATER CUT
% ============================================================

figure(32); clf;

plot(tPlot, WCPlot, 'b-', 'LineWidth', 1.8);

grid on;
xlabel('Time, days');
ylabel('Water cut, fraction');
title('Water cut versus time');
ylim([0 1]);

% ============================================================
% FIGURE 3: GAS-OIL RATIO
% ============================================================

figure(33); clf;

plot(tPlot, GORPlot, 'r-', 'LineWidth', 1.8);

grid on;
xlabel('Time, days');
ylabel('GOR, m3/m3');
title('Gas-oil ratio versus time');

% ============================================================
% FIGURE 4: INITIAL WATER SATURATION
% ============================================================

Sw0 = state0.s(:,1);

figure(34); clf;

plotCellData(Gdepth, Sw0, 'EdgeColor', 'none');

view(2);
set(gca, 'YDir', 'reverse');
axis tight;

xlabel('Radius, m');
ylabel('Absolute depth, m');
title('Initial water saturation, t = 0 days');

colorbar;
caxis([0 1]);

% ============================================================
% FIGURE 5: FINAL WATER SATURATION
% ============================================================

SwEnd = state11.s(:,1);

figure(35); clf;

plotCellData(Gdepth, SwEnd, 'EdgeColor', 'none');

view(2);
set(gca, 'YDir', 'reverse');
axis tight;

xlabel('Radius, m');
ylabel('Absolute depth, m');

title(sprintf('Final water saturation, t = %.1f days', t11/day));

colorbar;
caxis([0 1]);

% ============================================================
% SAVE FIGURES
% ============================================================

% Use the checkpoint directory as the results directory
plotDir = fileparts(checkpointFile11);

if ~exist(plotDir, 'dir')
    mkdir(plotDir);
end

drawnow;

print(31, fullfile(plotDir, '01_Production_rates.png'), '-dpng', '-r150');
print(32, fullfile(plotDir, '02_Water_cut.png'), '-dpng', '-r150');
print(33, fullfile(plotDir, '03_GOR.png'), '-dpng', '-r150');
print(34, fullfile(plotDir, '04_Sw_initial.png'), '-dpng', '-r150');
print(35, fullfile(plotDir, '05_Sw_final.png'), '-dpng', '-r150');

fprintf('\nFive figures saved in:\n%s\n', plotDir);
fprintf('=== STAGE 12 COMPLETE ===\n');
% ============================================================
