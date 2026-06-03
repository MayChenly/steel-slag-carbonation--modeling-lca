clear all

country_emission_factor = 0.21741;
T = readtable('C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\BF\BF_Indirect_dissolution_result.xlsx');
colNames = T.Properties.VariableNames;
BF_steel_slag_kg = T.(colNames{1});  
Dissolution_time_min = T.(colNames{2});
CaCO3_Concentration_molperL = T.(colNames{4});
precipitation_time_h = T.(colNames{5});
Q_feed_m3_perh = T.(colNames{6});
V = 2000; %L liquid
CO2_molar_mass = 44; % g
conversion_ratio = 1000 / BF_steel_slag_kg;

% Fixed variables
CO2_concentration = 0.1; % bar
CO2_gas_product_DAC = 1 ; % ton
CO2_stored_kg = CaCO3_Concentration_molperL * V * CO2_molar_mass /1000;
CO2_supplied_kg = CO2_stored_kg;

 % DAC option2
CO2_removed_from_air = 1 ; % tonne
electrcity_for_010_bar_CO2 = 4552.583826 / 3.6 ; % kwh 0.1 bar

% Crushing energy
W_i = 0.0135;        % kWh/kg
BF_D_sm = 0.0025;        % m
dp = 1e-5;               % m
E_crushing = 0.01 * W_i * (1/ sqrt(dp) - 1 / sqrt(BF_D_sm)) * BF_steel_slag_kg; % kwh

% Reacotr1
E_reactor1 = 99.8121; % W

%Reactor2
% Parameters
rho_L = 1050;         % Density of liquid (kg/m^3)
mu_L = 1.2e-3;       % Viscosity (Pa·s)
N = 1.5;              % Impeller speed (rps)
D = 0.6;              % Impeller diameter (m)
Di = 0.12;             %the width of the impeller blade (m)
VL = 2;                % the liquid volume (m^3)
g = 9.81;             % Gravity (m/s^2)
QG = Q_feed_m3_perh/3600;      %  volumetric gas flow rate m3/s
Re_L = (rho_L * N * D^2) / mu_L;
Fr_L = (D * N^2) / g;
Np_1 = 19.5 * Re_L^(-0.3);
Np_2 = 24.0 * (Re_L * Fr_L)^(-1/3);
N_p = min(Np_1, Np_2);
P_0 = rho_L * N^3 * D^5 * N_p;
term1 = (QG / (N * VL))^(-0.25);
term2 = ((N^2 * D^4) / (g * Di * VL^(2/3)))^(-0.2);
PG_P0 = 0.1 * term1 * term2;
PG = P_0*PG_P0; % W

% Fan energy for exatra pressure
h_L = 1;                % m
total_pressure =1 ;     % bar
eta = 0.85*0.95;
gamma = 1.28;
delta_P = rho_L * g * h_L;  %Pa
P_in = total_pressure * 1e5; %Pa
P_out = P_in + delta_P;         % Pa
E_fan = (1 / eta) * P_in * QG * gamma / (gamma-1) * ((P_out / P_in)^(1-1/gamma) - 1);% W

% LCA process_for 10 kg steel slag
E_DAC = electrcity_for_010_bar_CO2 /1000  *CO2_supplied_kg; % kwh
E_BPMED_system = 17328.25801 * (V/2) /(3.6e6);  %kwh
E_stirring_reactor1 = E_reactor1 /1000 * Dissolution_time_min/60;  %kwh
E_stirring_reactor2 = PG/1000 * precipitation_time_h;   %kwh
E_fan_energy = E_fan/1000 * precipitation_time_h; %kwh

E_total = E_DAC+E_BPMED_system+E_stirring_reactor1+E_stirring_reactor2+E_fan_energy+E_crushing; %kwh

%LCA process emission
E_total_emission = E_total * country_emission_factor; %kg

E_net = E_total_emission - CO2_stored_kg;
E_net_per_tonne = E_net * conversion_ratio; %kgCO2/tonne steel slag

% 输出数据（1行是名称，1行是数值）
header = {'DAC', 'BPMED system', 'Stirring in dissolution process', ...
          'Stirring in precipitation process', 'Fan energy', 'Crushing', ...
          'Total emission', 'Net emission', 'Net emission per tonne steel slag'};

data = [E_DAC *country_emission_factor, E_BPMED_system *country_emission_factor, E_stirring_reactor1 *country_emission_factor, ...
        E_stirring_reactor2 *country_emission_factor, E_fan_energy*country_emission_factor, E_crushing*country_emission_factor, ...
        E_total_emission, E_net, E_net_per_tonne];

% 转换为单元格格式以写入 Excel
output_cell = [header; num2cell(data)];

% 写入 Excel
filename = 'BF_energy_output.xlsx';
writecell(output_cell, filename);
