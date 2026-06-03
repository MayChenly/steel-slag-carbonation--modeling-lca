clear all

% 读取 Excel Sheet3 所有数据
filename = 'C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\single_analysis\BOF_particle_size.xlsx';
sheet = 'Sheet3';
data = readmatrix(filename, 'Sheet', sheet);

% 提取数据
x = 1:5;
labels = {'1e-2', '1e-3', '1e-4', '1e-5', '1e-6'};

y1 = data(:, 5);  % Stirring
y2 = data(:, 6);  % Crushing
y3 = data(:, 7);  % Total

% 绘图
figure;
hold on;
set(gca, 'FontSize', 12);

% 使用统一风格的配色
plot(x, y1, '--', 'LineWidth', 2, ...
    'Color', [0.00 0.45 0.74], ...
    'DisplayName', 'Stirring energy in dissolution process');

plot(x, y2, '--', 'LineWidth', 2, ...
    'Color', [0.85 0.33 0.10], ...
    'DisplayName', 'Crushing energy');

plot(x, y3, '-^', 'LineWidth', 2.5, ...
    'Color', [0.47 0.67 0.19], ...
    'MarkerFaceColor', [0.47 0.67 0.19], ...
    'MarkerSize', 7, ...
    'DisplayName', 'Total energy');

% 设置横坐标标签
set(gca, 'XTick', x, 'XTickLabel', labels);
xlabel('Particle size (m)', 'FontSize', 12);
ylabel(['Energy Consumption (kWh)'], 'FontSize', 12);
title('Energy Consumption by Particle Size', 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 10);
grid on;
box on;
