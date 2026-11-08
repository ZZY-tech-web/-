%% 绘制校正前后的响应曲线（依赖 sequential_flow 的 results）
% 用法：先运行 sequential_flow，再运行本脚本；或直接运行本脚本（会自动调用前者）
% 图窗会弹出来，同时把 PNG 存到项目根目录的 figs/ 下，方便写报告
if ~exist('results', 'var') || isempty(results)
    fprintf('未找到 results，先运行 sequential_flow ...\n');
    sequential_flow;
end

% ---------- 输出目录 ----------
here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
figDir = fullfile(here, '..', 'figs');
if ~exist(figDir, 'dir'), mkdir(figDir); end

nm   = {results.name};
nSt  = numel(results);
cols = lines(nSt);

% 参考模型前馈（指令整形）参数，取自 sequential_flow 的设计结果
wf = results(1).wfRef;  zf = results(1).zeRef;

%% ========== 图 1+2 合并：2 行 3 列（第一行纵向阶跃响应，第二行极点图）==========
f12 = figure('Name', '纵向阶跃响应与极点', 'Color', 'w', ...
    'Position', [80 80 1200 800]);

% ---------- 第一行：三个状态的纵向 q 阶跃响应 ----------
for k = 1:nSt
    A2 = results(k).longitudinalA;
    B2 = results(k).longitudinalB;
    A3 = [A2, B2; 0 0 -1/tau];
    B3 = [0; 0; 1/tau];
    Acl3 = A3 - B3*results(k).K3;
    [numCl, denCl] = ss2tf(Acl3, B3, [0 1 0], 0);
    Gcl = tf(numCl, denCl) * results(k).Kff;      % 稳态归一化为 1

    subplot(2, nSt, k);                            % 第一行第 k 张
    t = 0:0.005:8;
    y0 = step(Gcl, t);
    F  = tf(wf^2, [1, 2*zf*wf, wf^2]);
    y1 = step(Gcl*F, t);
    plot(t, y0, 'Color', cols(k,:), 'LineWidth', 1.8); hold on;
    plot(t, y1, '--', 'Color', [0.45 0.45 0.45], 'LineWidth', 1.8);
    plot([0 8], [1 1], 'k:', 'LineWidth', 1.0);
    grid on; box on;
    xlabel('t (s)'); ylabel('q / q_{cmd}');
    title(sprintf('%s\n\\omega_n=%.2f, \\zeta=%.2f', nm{k}, ...
        results(k).clWn, results(k).clZe));
    if k == 1
        legend('无前馈整形', sprintf('参考模型前馈 \\omega_f=%.1f', wf), ...
            'Location', 'southeast');
    end
end

% ---------- 第二行：三个状态的纵向极点图（每个状态一张，开环○ + 闭环×）----------
for k = 1:nSt
    subplot(2, nSt, nSt + k);                      % 第二行第 k 张
    hold on; grid on; box on;

    % 该状态闭环极点（三状态相同：-20.202, -1.5±1.323j）
    A2 = results(k).longitudinalA;
    B2 = results(k).longitudinalB;
    A3 = [A2, B2; 0 0 -1/tau];
    B3 = [0; 0; 1/tau];
    p1 = eig(A3 - B3*results(k).K3);
    hCL = plot(real(p1), imag(p1), 'x', 'Color', 'k', ...
        'MarkerSize', 12, 'LineWidth', 2.0);

    % 该状态开环(本体)极点
    p0 = results(k).longitudinalPoles;
    h0 = plot(real(p0), imag(p0), 'o', 'Color', cols(k,:), ...
        'MarkerSize', 9, 'LineWidth', 1.6);

    plot([0 0], [-3 3], 'k-', 'LineWidth', 1.0);
    xlim([-3.2, 1.0]); ylim([-2.2, 2.2]);
    xlabel('Re(s)'); ylabel('Im(s)');
    title(sprintf('%s\n纵向极点', nm{k}));
    legend([h0, hCL], {'开环(本体)', '闭环(校正后)'}, ...
        'Location', 'southwest');

    % 只在第一张子图放备注，避免重复
    if k == 1
        text(-3.1, 1.95, '注：闭环另有一个舵机极点 -20.2，在坐标范围之外', ...
            'FontSize', 8);
    end
end

printFig(f12, fullfile(figDir, 'fig12_longitudinal_step_poles.png'));

%% ================= 图 3：横向荷兰滚响应（初始 beta=1deg 扰动） =================
f3 = figure('Name', '横向荷兰滚响应', 'Color', 'w', 'Position', [160 120 500 1000]);
t = 0:0.01:10;
b0 = 1*pi/180;
for k = 1:nSt
    Al = results(k).lateralA;
    Bl = results(k).lateralB;
    Tw = results(k).Tw;   Kr = results(k).Kr;
    A5 = [Al, zeros(4,1); 0, 0, 1/Tw, 0, -1/Tw];
    B5 = [Bl; 0, 0];
    Acl5 = A5 + B5(:,2)*(Kr*[0, 0, 1, 0, -1]);

    sysOL = ss(Al, Bl, [0 0 1 0], 0);
    yOL = initial(sysOL, [b0; 0; 0; 0], t);
    sysCL = ss(Acl5, zeros(5,1), [0 0 1 0 0], 0);
    yCL = initial(sysCL, [b0; 0; 0; 0; 0], t);

    subplot(nSt, 1, k);                            % 改为 3×1 竖直排列
    plot(t, yOL*180/pi, 'Color', [0.6 0.6 0.6], 'LineWidth', 1.8); hold on;
    plot(t, yCL*180/pi, 'Color', cols(k,:), 'LineWidth', 1.8);
    grid on; box on;
    xlabel('t (s)'); ylabel('r (deg/s)');
    title(sprintf('%s\n\\zeta_{dr}: %.3f \\rightarrow %.3f', nm{k}, ...
        results(k).drZe0, results(k).drZe));
    if k == 1
        legend('开环', '闭环(偏航阻尼器)', 'Location', 'best');
    end
end
printFig(f3, fullfile(figDir, 'fig3_dutch_roll.png'));

%% ================= 图 4（可选，默认注释）：0 度根轨迹 =================
% 说明：状态反馈是多回路（alpha + q），单个增益的根轨迹并不经过设计极点，
%       所以这张图只能作为"单回路角速度反馈"的对照，写报告时不建议单列。
% 需要时把下面的 %{ %} 去掉即可。
%{
k = min(2, nSt);
G = results(k).longitudinalTF * tf(1, [tau 1]);
f4 = figure('Name', '0度根轨迹', 'Color', 'w', 'Position', [200 140 700 700]);
rlocus(-G);            % 单位正反馈 => 0 度根轨迹用 rlocus(-L)
grid off;
title(sprintf('%s 的 0° 根轨迹（q 单回路，含舵机）', nm{k}));
xlim([-24, 2]); ylim([-6, 6]);
printFig(f4, fullfile(figDir, 'fig4_rlocus.png'));
%}

fprintf('\n图片已保存到：%s\n', figDir);
fprintf('  图1+2 纵向阶跃响应与极点（2×3）\n');
fprintf('  图3 横向荷兰滚响应（开环 vs 闭环）\n');

%% ================= 局部函数 =================
function printFig(f, path)
% 把图窗改成适合打印的浅色，再存成 PNG
    try
        theme(f, 'light');           % R2025a+ 可用
    catch
    end
    ax = findobj(f, 'Type', 'axes');
    set(ax, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
    tx = findobj(f, 'Type', 'text'); %#ok<NASGU>
    set(findobj(f, 'Type', 'text'), 'Color', 'k');
    lg = findobj(f, 'Type', 'legend');
    if ~isempty(lg)
        try, set(lg, 'TextColor', 'k', 'Color', 'w'); catch, end
    end
    try
        print(f, '-dpng', '-r140', path);
    catch
        saveas(f, path);
    end
end