clear all

%% === 读取主数据 ===
T = readtable('C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\EAF\EAF_Indirect_dissolution_result.xlsx');
colNames = T.Properties.VariableNames;

EAF_steel_slag_kg = T.(colNames{1});
Dissolution_time_min = T.(colNames{2});
CaCO3_Concentration_molperL = T.(colNames{4});
precipitation_time_h = T.(colNames{5});
Q_feed_m3_perh = T.(colNames{6});

%% === 读取 emission factor 表格（带国家名）===
EF_table = readtable('C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\EAF\country_information.xlsx');
country_names = EF_table{:,1};            % 国家名
country_emission_factors = EF_table{:,11}; % 对应 emission factor 值

%% === 固定参数 ===
V = 2000; % L
CO2_molar_mass = 44; % g/mol
electrcity_for_010_bar_CO2 = 4552.583826 / 3.6; % kWh/ton CO2
E_BPMED_system = 17328.25801 * (V / 2) / 3.6e6; % kWh

% Crushing energy
W_i = 0.0135;
EAF_D_sm = 0.0025;
dp = 1e-5;
E_crushing = 0.01 * W_i .* (1 ./ sqrt(dp) - 1 ./ sqrt(EAF_D_sm)) .* EAF_steel_slag_kg;

% Reactor1 stirring energy
E_reactor1 = 99.8121; % W
E_stirring_reactor1 = E_reactor1 / 1000 .* Dissolution_time_min / 60; % kWh

% Reactor2 stirring and fan
rho_L = 1050;
mu_L = 1.2e-3;
N = 1.5;
D = 0.6;
Di = 0.12;
VL = 2;
g = 9.81;
QG = Q_feed_m3_perh ./ 3600;

Re_L = (rho_L * N * D^2) / mu_L;
Fr_L = (D * N^2) / g;
Np_1 = 19.5 * Re_L^(-0.3);
Np_2 = 24.0 * (Re_L * Fr_L)^(-1/3);
N_p = min(Np_1, Np_2);
P_0 = rho_L * N^3 * D^5 * N_p;

term1 = (QG ./ (N * VL)).^(-0.25);
term2 = ((N^2 * D^4) / (g * Di * VL^(2/3))).^(-0.2);
PG_P0 = 0.1 .* term1 .* term2;
PG = P_0 .* PG_P0;
E_stirring_reactor2 = PG ./ 1000 .* precipitation_time_h; % kWh

% Fan energy
h_L = 1;
total_pressure = 1; % bar
eta = 0.85 * 0.95;
gamma = 1.28;
delta_P = rho_L * g * h_L;
P_in = total_pressure * 1e5;
P_out = P_in + delta_P;
E_fan = (1/ eta)* P_in* QG* gamma/ (gamma - 1)* ((P_out/ P_in)^(1 - 1 / gamma) - 1);
E_fan_energy = E_fan/ 1000* precipitation_time_h;

% CO2 stored
CO2_stored_kg = CaCO3_Concentration_molperL* V* CO2_molar_mass / 1000;
E_DAC = electrcity_for_010_bar_CO2/ 1000* CO2_stored_kg;
E_total = E_DAC + E_BPMED_system + E_stirring_reactor1 + E_stirring_reactor2 + E_fan_energy + E_crushing;
conversion_ratio = 1000/ EAF_steel_slag_kg;

%% === 遍历 emission factors 并计算 ===
n = length(country_emission_factors);
output = cell(n+1, 11);

% Header row
output(1,:) = {'Country', 'Emission factor', 'DAC', 'BPMED system', ...
               'Stirring dissolution', 'Stirring precipitation', ...
               'Fan energy', 'Crushing', 'Total emission', ...
               'Net emission', 'Net emission per tonne'};

% Loop over each country
for i = 1:n
    ef = country_emission_factors(i);

    dac_em = E_DAC * ef;
    bpmed_em = E_BPMED_system * ef;
    stir1_em = E_stirring_reactor1 * ef;
    stir2_em = E_stirring_reactor2 * ef;
    fan_em = E_fan_energy * ef;
    crush_em = E_crushing* ef;

    total_em = E_total * ef;
    net_em = total_em - CO2_stored_kg;
    net_em_tonne = net_em * conversion_ratio;

    output{i+1, 1} = country_names{i};
    output{i+1, 2} = ef;
    output{i+1, 3} = dac_em;
    output{i+1, 4} = bpmed_em;
    output{i+1, 5} = stir1_em;
    output{i+1, 6} = stir2_em;
    output{i+1, 7} = fan_em;
    output{i+1, 8} = crush_em;
    output{i+1, 9} = total_em;
    output{i+1,10} = net_em;
    output{i+1,11} = net_em_tonne;
end

%% === 写入 Excel ===
filename = 'EAF_energy_output_by_country.xlsx';
writecell(output, filename);
