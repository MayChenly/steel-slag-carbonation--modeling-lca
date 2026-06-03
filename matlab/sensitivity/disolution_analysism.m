clear all

% 读取 Excel 中 'actual time_min' 列
filename = 'C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\single_analysis\BOF_particle_size.xlsx';
sheet = 'Sheet3';

% 读取数据，假设 'actual time_min' 在某列（比如第1列）
% 如果知道列名，可以用 readtable 方便读取
T = readtable(filename, 'Sheet', sheet);

% 假设列名是 'actual_time_min'（注意变量名和Excel列名一致）
% 你可以查看 T.Properties.VariableNames 来确认列名
disp(T.Properties.VariableNames);

Dissolution_time_min = T.actual_time_min; % 取整列

% Parameters
rho_L = 1049;         % Density of liquid (kg/m^3)
mu_L = 1.05e-3;       % Viscosity (Pa·s)
N = 2;                % Impeller speed (rps)
D = 0.5;              % Impeller diameter (m)
g = 9.81;             % Gravity (m/s^2)

% Calculate Reynolds number
Re_L = (rho_L * N * D^2) / mu_L;

% Calculate Froude number
Fr_L = (D * N^2) / g;

% Calculate Power number (Np)
Np_1 = 19.5 * Re_L^(-0.3);
Np_2 = 24.0 * (Re_L * Fr_L)^(-1/3);
N_p = min(Np_1, Np_2);

% Calculate ungassed power input (P0)
P_0 = rho_L * N^3 * D^5 * N_p;

% Calculate E for each Dissolution_time_min
E = (P_0 / 1000) .* (Dissolution_time_min / 60); % kWh

% 显示结果
fprintf('Reynolds number (Re_L): %.2e\n', Re_L);
fprintf('Froude number (Fr_L): %.4f\n', Fr_L);
fprintf('Power number (N_p): %.4f\n', N_p);
fprintf('Ungassed power input (P_0): %.4f W\n', P_0);

% 如果多条时间，打印所有 E，或者只打印前几条
fprintf('Energy consumption E (kWh):\n');
disp(E);

% 给定参数
SS_total = 10;      % kg
W_i = 0.0135;        % kWh/kg
D_sm = 0.01;        % m

% dp 数组
dp = [1e-3, 1e-4, 1e-5, 1e-6];

% 计算 E_c
E_c = 0.01 * W_i * (1 ./ sqrt(dp) - 1 / sqrt(D_sm)) * SS_total;
disp(E_c)

% 画图
figure;
semilogx(dp, E_c, '-o', 'LineWidth', 2);
grid on;
xlabel('Particle size (m)');
ylabel(['Crushing energy consumption (kWh)']);
title('Steel slag crushing energy consumption');
set(gca, 'XDir','reverse'); % 使x轴从大到小

