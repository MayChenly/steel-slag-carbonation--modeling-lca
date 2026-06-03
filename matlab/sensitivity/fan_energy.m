clear all

% Parameters
rho_L = 1050;         % Density of liquid (kg/m^3)
g = 9.81;             % Gravity (m/s^2)
h_L = 1;              % Liquid height (m)
total_pressure = 1;   % bar
eta = 0.85 * 0.95;    % Fan efficiency
gamma = 1.28;         % Cp/Cv
delta_P = rho_L * g * h_L;       % Pa
P_in = total_pressure * 1e5;     % Convert bar to Pa
P_out = P_in + delta_P;          % Outlet pressure

% Define QG range (m^3/h)
QG_range = 1:120;
E_fan = zeros(size(QG_range));

% Loop to calculate E_fan for each QG
for i = 1:length(QG_range)
    QG = QG_range(i) / 3600;     % Convert to m^3/s
    E_fan(i) = (1 / eta) * P_in * QG * gamma / (gamma - 1) * ((P_out / P_in)^(1 - 1/gamma) - 1);  % W
end

% Plotting
figure
plot(QG_range, E_fan, '-x', 'LineWidth', 1.5)
xlabel('Gas Flow Rate QG (m^3/h)')
ylabel('Fan Energy E_{fan} (W)')
title('Fan Energy vs Gas Flow Rate')
grid on
