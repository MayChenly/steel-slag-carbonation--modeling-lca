clear all

% Parameters
rho_L = 1050;        % Density of liquid (kg/m^3)
mu_L = 1.2e-3;       % Viscosity (Pa·s)
N = 1.5;             % Impeller speed (rps)
D = 0.6;             % Impeller diameter (m)
Di = 0.12;           % Width of the impeller blade (m)
VL = 2;              % Liquid volume (m^3)
g = 9.81;            % Gravity (m/s^2)

% Fan energy parameters
h_L = 1;                     % Liquid height (m)
total_pressure = 1;          % bar
eta = 0.85 * 0.95;           % fan efficiency
gamma = 1.28;                % Cp/Cv for gas (e.g. CO2)

% Read QG and time from Excel Sheet3
filename = 'C:\Users\Liyuan Chen\Desktop\BOF_test.xlsx';      % Replace with your actual file name
data = readmatrix(filename, 'Sheet', 'Sheet3');

QG_values = data(:,2);       % Gas flow rates in m^3/h
time_h = data(:,3);          % Time in hours

% Ensure sizes match
if length(QG_values) ~= length(time_h)
    error('Mismatch between QG and time data lengths');
end

% Initialize arrays
PG = zeros(size(QG_values));        % Gassed power (W)
E_fan = zeros(size(QG_values));     % Fan power (W)
E_stir = zeros(size(QG_values));    % Stirring energy (J)
E_fan_total = zeros(size(QG_values)); % Fan energy (J)
E_total = zeros(size(QG_values));

% Calculate constants
Re_L = (rho_L * N * D^2) / mu_L;
Fr_L = (D * N^2) / g;
Np_1 = 19.5 * Re_L^(-0.3);
Np_2 = 24.0 * (Re_L * Fr_L)^(-1/3);
N_p = min(Np_1, Np_2);
P_0 = rho_L * N^3 * D^5 * N_p;

% Loop through all QG values
for i = 1:length(QG_values)
    QG = QG_values(i) / 3600;      % Convert to m^3/s
    t = time_h(i);                 % time in hours

    % Gassed power
    term1 = (QG / (N * VL))^(-0.25);
    term2 = ((N^2 * D^4) / (g * Di * VL^(2/3)))^(-0.2);
    PG_P0 = 0.1 * term1 * term2;
    PG(i) = P_0 * PG_P0;

    % Fan energy
    delta_P = rho_L * g * h_L;        %pa
    P_in = total_pressure * 1e5;      %pa
    P_out = P_in + delta_P;           %pa
    E_fan(i) = (1 / eta) * P_in * QG * gamma / (gamma-1) * ((P_out / P_in)^(1 - 1/gamma) - 1);   % W

    % Multiply by time to get energy (in kWh)
    E_stir(i) = PG(i)/1000 * t;
    E_fan_total(i) = E_fan(i)/1000 * t;
    E_total(i) = E_stir(i)+E_fan_total(i)+2.529213;
end

% Plot
figure
plot(QG_values, E_stir, '-o', 'DisplayName', 'Stirring Energy (kWh)')
hold on
plot(QG_values, E_fan_total, '-x', 'DisplayName', 'Fan Energy (kWh)')
hold on
plot(QG_values, E_total, '-s', 'DisplayName', 'Total (kWh)')

xlabel('Gas Flow Rate QG (m^3/h)')
ylabel('Energy (kWh)')
title('Total Energy vs Gas Flow Rate')
legend('Location', 'northeast')
grid on


% 确保所有变量都是列向量
QG_values = QG_values(:);
time_h = time_h(:);
E_stir = E_stir(:);
E_fan_total = E_fan_total(:);

% 创建并显示表格
T = table(QG_values, time_h, E_stir, E_fan_total, ...
    'VariableNames', {'QG_m3_per_h', 'Time_h', 'Stirring_kWh', 'Fan_kWh'});

disp(T)


%disp(QG_values)
%disp(time_h)

% 读取数据
data1 = readmatrix(filename, 'Sheet', 'Sheet4');
Q_feed = data1(:,2);
time = data1(:,3);               % 时间（小时）
stirring_energy = data1(:,9);    % 搅拌能耗（kWh）
extra_pressure = data1(:,10);    % 风机能耗（kWh）
E_total = stirring_energy + extra_pressure;  % 总能耗

% 创建图形
figure
set(gcf, 'Color', 'w');  % 设置背景为白色

% 主坐标轴（能耗）
yyaxis left
p1 = plot(Q_feed, stirring_energy, '--', 'LineWidth', 2, ...
    'Color', [0.00 0.45 0.74], 'DisplayName', 'Stirring Energy');

hold on
p2 = plot(Q_feed, extra_pressure, '--', 'LineWidth', 2, ...
    'Color', [0.85 0.33 0.10], 'DisplayName', 'Fan Energy');

p3 = plot(Q_feed, E_total, '-^', 'LineWidth', 2.5, ...
    'Color', [0.47 0.67 0.19], 'MarkerSize', 7, ...
    'DisplayName', 'Total Energy');

ylabel('Energy Consumption (kWh)', 'FontSize', 12)
ax = gca;
ax.YColor = [0 0 0];

% 副坐标轴（时间）-- 使用圆形散点
yyaxis right
p4 = scatter(Q_feed, time, 80, 'o', 'filled', ...
    'MarkerFaceColor', [0.49 0.18 0.56], ...
    'DisplayName', 'Precipitation Time');


ylabel('Precipitation Time (h)', 'FontSize', 12)
ax.YAxis(2).Color = [0.3 0.3 0.3];

% 横坐标和标题
xlabel('CO_2 Gas Flow Rate (m^3/hour)', 'FontSize', 12)
title('Variation of Energy Consumption with CO_2 Feed Flow Rate', 'FontSize', 14)

% 图例
legend([p1 p2 p3 p4], ...
    {'Stirring Energy', 'Fan Energy', 'Total Energy', 'Precipitation Time'}, ...
    'Location', 'northwest', 'FontSize', 10)

% 样式美化
grid on
box on
set(gca, 'FontSize', 11, 'LineWidth', 1.2)



% 读取数据
data2 = readmatrix(filename, 'Sheet', 'Sheet5');
CO2_concentration = data2(:,6);    % CO₂ partial pressure (bar)
time = data2(:,3);                 % 时间（小时）
DAC = data2(:,8);                  % DAC CO₂ 浓度
stirring_energy = data2(:,9);      % 搅拌能耗（kWh）
extra_pressure = data2(:,10);      % 风机能耗（kWh）
E_total = data2(:,11);             % 总能耗（已有数据）

% 创建图形窗口
figure
set(gcf, 'Color', 'w');

% 主坐标轴：能耗
yyaxis left
p1 = plot(CO2_concentration, stirring_energy, '--', 'LineWidth', 2, ...
    'Color', [0.00 0.45 0.74], 'DisplayName', 'Stirring Energy');
hold on

p2 = plot(CO2_concentration, extra_pressure, '--', 'LineWidth', 2, ...
    'Color', [0.85 0.33 0.10], 'DisplayName', 'Fan Energy');

p3 = plot(CO2_concentration, E_total, '-^', 'LineWidth', 2.5, ...
    'Color', [0.47 0.67 0.19], 'MarkerSize', 6, ...
    'DisplayName', 'Total Energy');

% DAC 曲线，颜色换为更明显的深橙色
p5 = plot(CO2_concentration, DAC, '--', 'LineWidth', 2, ...
    'Color', [0.93 0.45 0.10], 'DisplayName', 'DAC System');

ylabel('Energy Consumption (kWh)', 'FontSize', 12)
ax = gca;
ax.YColor = [0 0 0];

% 副坐标轴：时间
yyaxis right
p4 = scatter(CO2_concentration, time, 80, 'o', 'filled', ...
    'MarkerFaceColor', [0.49 0.18 0.56], ...
    'DisplayName', 'Precipitation Time');

ylabel('Precipitation Time (h)', 'FontSize', 12)
ax.YAxis(2).Color = [0.3 0.3 0.3];

% 横坐标设置为标签
xticks([0.05 0.1 0.15 0.2])
xticklabels({'0.05', '0.10', '0.15', '0.20'})
xlabel('CO_2 Concentration (bar)', 'FontSize', 12)

% 标题
title('Energy Consumption at Various CO_2 Concentration', 'FontSize', 14)

% 图例
legend([p1 p2 p3 p5 p4], ...
    {'Stirring Energy', 'Fan Energy', 'Total Energy', 'DAC System', 'Precipitation Time'}, ...
    'Location', 'northwest', 'FontSize', 10)

% 美化
grid on
box on
set(gca, 'FontSize', 11, 'LineWidth', 1.2)
