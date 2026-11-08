%% 原系统根轨迹（含舵机）+ 状态反馈设计极点对照（仅第二种状态）
%  论证：根轨迹只有 1 个自由度，复分支被"锁"在一条近似竖直的渐近线上，
%        所以极点无法放到设计点 (wn=2.0, zeta=0.75) 上 —— 该点不在轨迹上。
if ~exist('results', 'var') || isempty(results)
    sequential_flow;
end

here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
figDir = fullfile(here, '..', 'figs');
if ~exist(figDir, 'dir'), mkdir(figDir); end

nm  = {results.name};
nSt = numel(results);

k = 2;   % 只绘制第二种状态

f = figure('Color', 'w', 'Position', [50 60 700 700]);

A2 = results(k).longitudinalA;
B2 = results(k).longitudinalB;
A3 = [A2, B2; 0, 0, -1/tau];
B3 = [0; 0; 1/tau];
C3 = [0 1 0];
[nq, dq] = ss2tf(A3, B3, C3, 0);
op = eig(A3);
zz = roots(nq);
cent = (sum(op) - sum(zz))/(numel(op) - numel(zz));

% ---------- 根轨迹：连续曲线（0° 根轨迹 = rlocus(-G)）----------
G = tf(nq, dq);
rlocus(-G, logspace(-3, 2.2, 1500));
hold on;

% 只把根轨迹曲线加粗变蓝（Marker='none' 的是曲线，'x'/'o' 是开环极点/零点标记）
hRL = findobj(gca, 'Type', 'line');
for h = hRL'
    if strcmp(get(h, 'Marker'), 'none')
        set(h, 'LineWidth', 1.6, 'Color', [0.15 0.4 0.8]);
    end
end

% ---------- 一级品质区域边界：ζ=0.35, ωn=1.0 ----------
zeMin = 0.35;
th    = acos(zeMin);          % ≈ 69.5°
R     = 20;
% ζ=0.35 射线（上下两支）
plot([0, -R*cos(th)], [0,  R*sin(th)], 'r--', 'LineWidth', 2.2);
plot([0, -R*cos(th)], [0, -R*sin(th)], 'r--', 'LineWidth', 2.2);
% ωn=1 圆
tt = linspace(0, 2*pi, 400);
plot(cos(tt), sin(tt), 'r--', 'LineWidth', 2.2);

% 边界文字标注（放在可见范围内）
text(-3.4, 6.0, '\zeta=0.35', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold');
text(0.25, 1.25, '\omega_n=1', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold');
text(-8.5, 6.3, '一级品质区域', 'FontSize', 11, 'Color', 'r', ...
    'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(-8.5, -6.3, ...
    '一级品质判据：\zeta \geq 0.35，\omega_n \geq 1.0，\zeta \leq 1.30', ...
    'FontSize', 9, 'Color', 'r', 'HorizontalAlignment', 'center');

% ---------- 开环极点 / 零点 ----------
plot(real(op), imag(op), 'x', 'Color', 'k', 'MarkerSize', 11, 'LineWidth', 2.0);
plot(real(zz), imag(zz), 'o', 'Color', 'k', 'MarkerSize', 9, 'LineWidth', 1.8);

% ---------- 状态反馈设计出的闭环极点 ----------
dp = results(k).clPoles;
plot(real(dp), imag(dp), 'p', 'MarkerSize', 15, ...
     'MarkerFaceColor', [0.85 0.1 0.1], 'MarkerEdgeColor', 'k');
text(-1.3, 3.0, '状态反馈闭环极点', 'FontSize', 9, 'Color', [0.75 0.05 0.05]);

plot([0 0], [-7 7], 'k-', 'LineWidth', 1.0);
xlim([-14, 1.5]); ylim([-7, 7]);
xlabel('Re(s)  (1/s)'); ylabel('Im(s)  (1/s)');
title(sprintf('%s 的 0° 根轨迹（含舵机）', nm{k}), 'FontSize', 10);
grid on; box on;

fprintf('\n%s: 渐近线 Re=%.2f；开环极点 %s；零点 %s\n', nm{k}, cent, ...
    mat2str(round(op.', 3)), mat2str(round(zz.', 3)));
fprintf('  状态反馈设计极点 %s（不在根轨迹上）\n', ...
    mat2str(round(dp.', 3)));

try, theme(f, 'light'); catch, end
set(findobj(f, 'Type', 'axes'), 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
% 注意：不再统一 set 文字颜色为黑，否则红色品质标注会被覆盖

outPng = fullfile(figDir, 'fig6_rootlocus_state2.png');
try
    print(f, '-dpng', '-r140', outPng);
catch
    saveas(f, outPng);
end
fprintf('\n图已保存：%s\n', outPng);