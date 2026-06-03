% 读取数据
data = readmatrix('C:\\Users\\Liyuan Chen\\Desktop\\indirect\\results\\LCApart\\single_analysis\\BOF_particle_size.xlsx', 'Sheet', 'Sheet2');
labels = arrayfun(@(x) sprintf('1e-%d m', x), 2:6, 'UniformOutput', false);

% 自定义颜色（对比度高）
colorList = [
    0.00, 0.45, 0.74;   % 蓝
    0.85, 0.33, 0.10;   % 红
    0.93, 0.69, 0.13;   % 黄
    0.47, 0.67, 0.19;   % 绿
    0.49, 0.18, 0.56    % 紫
];

% 创建图窗
figure;
set(gcf, 'Position', [100 100 800 600]);

% ---------------- 主图 ----------------
mainAx = axes;
hold(mainAx, 'on');
set(mainAx, 'FontSize', 12);
axis(mainAx, 'square');

lineHandles = gobjects(1, 5);

% 前3条线
for i = 1:3
    x = data(:, 2*i - 1);
    y = data(:, 2*i);
    lineHandles(i) = plot(mainAx, x, y, 'LineWidth', 2, 'Color', colorList(i,:));
end

xlabel(mainAx, 'Time (min)', 'FontSize', 12);
ylabel(mainAx, 'Ca^{2+} concentration (M)', 'FontSize', 12);
title(mainAx, 'The Effect of Particle Size on Dissolution Rate', 'FontSize', 14);
xlim(mainAx, [0 2880]);
ylim(mainAx, [0 0.05]);

grid(mainAx, 'on');
box(mainAx, 'on');

% ---------------- 插图：嵌入主图内部 ----------------
% 插图相对于主图坐标系统 (normalized) 嵌套
insetAx = axes('Parent', gcf, 'Units', 'normalized', ...
               'Position', [0.5 0.15 0.35 0.35]);  % 右下角，主图内
set(insetAx, 'FontSize', 9);
hold(insetAx, 'on');
axis(insetAx, 'square');

% 后2条线
for i = 4:5
    x = data(:, 2*i - 1);
    y = data(:, 2*i);
    lineHandles(i) = plot(insetAx, x, y, 'LineWidth', 2, 'Color', colorList(i,:));
end

xlim(insetAx, [0 60]);
grid(insetAx, 'on');
box(insetAx, 'on');

% ---------------- 图例 ----------------
legend(mainAx, lineHandles, labels, ...
       'Location', 'northeast', 'FontSize', 10, 'Box', 'on');
