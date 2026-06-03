% This code applies two different methods for solving a stiff ODE for n compartments
clear all

global t_record t_ch_record t_Diff_record
t_record = [];
t_ch_record = [];
t_Diff_record = [];

% Set up global variables
global ep tp ks0 Ek rp0 pore_coef T_coef_1 T_coef_2 T_coef_0 min_rp total_pressure Mass_ss CO2max_l Q_feed CCO2_in t_new R_l Q_feed_values t_Q_feed CCO2_e V L e A SS_density SS_total MCao pCO2_in  Mr Do  dp T n_com V_CO2 Gt Q_out_final recorded_time control_interval CO2_max_stored ks rho_CaO Dco2 Dk Q_reduction

% Set up global variables
%global total_pressure Mass_ss CO2max_l Q_feed CCO2_in t_new R_l Q_feed_values t_Q_feed CCO2_e V L e A SS_density SS_total MCao pCO2_in  Mr Do  dp T n_com V_CO2 Gt Q_out_final recorded_time control_interval CO2_max_stored ks rho_CaO Dco2 Dk Q_reduction

control_interval = 1; % Seconds, Q_feed is checked every 1 second
recorded_time = 0;

% Set up the chamber characteristics

V = 1e-1; % Volume of chamber, m^3
L = 1e-1; % Length of chamber, m
A = V / L; % Cross-sectional area of chamber, m^2
e = 0.4; % Porosity of the steel slag particle bed

% AY note: use 1 compartment for now, to test the model quickly
n_com = 15; % Number of compartments in the chamber
V_CO2 = V * e / n_com;   % Volume of CO2, cm^3

pCO2_in = 1; % CO2 concentration in tank, bar
T =  600+273.15; % Temperature, K
rp0 = 20 * 10 ^ (-9); % Average pore diameter, m

para = [-1.8254    4.8309    1.5884    1.9243  -10.8252    4.8094    7.6202];
ks0 = 10^para(1);
Ek = 10^para(2);
pore_coef = para(3);
T_coef_1 = para(4);
min_rp = 10^para(5);
T_coef_2 = para(6);
T_coef_0 = para(7);

%%%AY a larger particle size adopted now; the code should also work for
%%%smaller particles
dp = 1e-6; %60 * 10 ^ (-4); % Average particle size, m

%%%AY11May the blow is updated according to the paper
%MW_CaOH2 = 74.1;
%MW_CaO = 56.08;
MCao = 0.3940*0.5113; % Tian et al paper, 0.5113 is reactive CaO fraction

Mr = 0.7857; % Molar mass ratio of CO2 to CaO (no unit)

initial_residence_time = 0.000188; % Hours
Q_feed = V / (initial_residence_time * 3600);          % Flow rate of CO2, m^3/s

% Set up the steel slag characteristics
SS_density = 4.07 * 10^3;                              % Steel slag density, kg/m^3
SS_total = V * (1 - e) * SS_density;        % Total mass of steel slag, kg
disp(['SS_total_mass(kg): ', num2str(SS_total)]);

% Set up diffusivity (Do)
T0 = 273.15; % Temperature, K

vi = 26.9; % CO2, cm^3/mol
vj = 20.1; % Air, cm^3/mol
Mi = 44.01; % CO2, g/mol
Mj = 28.97; % Air, g/mol
ep = 0.1205; % Porous steel slag porosity
tp = 13.47; % Porous steel slag tortuosity
R = 8.314; % J/(mol*K)


rho_CaO = (1 - e) * SS_density * MCao / (56 * 10^(-3));             % CaO density in steel slag particle, mol/m3

CCO2_e = 0; %1.826e6 / (R * T) * exp(-19680 / T)*1e6;       % original unit mol/cm3, converted tp mol/m3


Mass_ss = SS_total / n_com; % Mass of per compartment steel slag, kg
CO2max_l = MCao * Mr * SS_total; % Maximum CO2 uptake, kg
CO2_max_stored = CO2max_l / SS_total;
disp(['CO2_max_stored(kg/kgSS): ', num2str(CO2_max_stored)]);

% Set up the CO2 continuous system
t_new = .00;
%%%AY the value below looks very high; set to zero for now.

CCO2_in = pCO2_in / (R * T) * 1e5;     % CO2 concentration in tank, mol/m3
total_pressure = 1; % Bar
Gt = total_pressure * 1e5 / (R * T); % Total gas mole concentration, mol/m^3




% Initial values for the ODE function
m0 = 1e-6;
dE_dt_init = 0; % Energy(0), J
X0 = 0; %initial conversion
CCO2_0 = 400e-6*Gt; % assuming air in reactor initially
y0 = [repmat([X0], 1, n_com), m0, dE_dt_init]; % Initial values
carbonation_length = 1000; % Carbonation duration, in hours
tspan = [0 carbonation_length * 3600]; % Duration in seconds
opts = odeset('Events', @myEventFcn, 'RelTol', 1e-8, 'AbsTol', 1e-8);
R_l = []; % List of R, CO2 uptake per second
Q_feed_values = [Q_feed];
t_Q_feed = [0];
[t, y] = ode15s(@odegunc_A, tspan, y0, opts);

% Plot the results

%figure
plot(t/3600,y(:,n_com+1),'b');                  % CO2 captured
hold on;
title(['The amount of CO2 stored in Steel slag']);
ylabel('total CO2 stored (kg)');
xlabel('Duration (hour)');
hold off

% 当前数据
time = t / 3600;
co2 = y(:, n_com + 1);

% 转为 table
data_table = table(time, co2);
data_table.Properties.VariableNames = {'Time_hour', 'CO2_kg'};

% 文件名
filename = 'BOF_CO2_captured_data.xlsx';

% 自动选择新 sheet 名
sheet_base = 'Run_';
sheet_num = 1;

% 查找未占用的 sheet 名
while true
    try
        [~, sheets] = xlsfinfo(filename);
        if any(strcmp([sheet_base num2str(sheet_num)], sheets))
            sheet_num = sheet_num + 1;
        else
            break;
        end
    catch
        break; % 文件不存在，直接写
    end
end

% 构建 sheet 名
sheet_name = [sheet_base num2str(sheet_num)];

% 写入 Excel 文件的对应 sheet
writetable(data_table, filename, 'Sheet', sheet_name);

specific_y_column = y(:, n_com + 1);
CO2_total_stored = max(specific_y_column);   % kg
disp(['CO2_max_stored(kg)：', num2str(CO2max_l)]);
disp(['CO2_total_stored(kg)：', num2str(CO2_total_stored)]);
disp(['CO2_total_stored(kg/kg slag)：', num2str(CO2_total_stored/SS_total)]);
disp(['carbonation degree：', num2str(CO2_total_stored/CO2max_l)]);

%figure
plot(t/3600,y(:,n_com+2)/(1e6),'b');                  % Energy consuption 
hold on;
title('Fan energy consumption');
ylabel('Fan Energy (MJ)');
xlabel('Duration (hour)');
hold off

a = t / 3600; 
b_values = y(:, n_com + 2) / 1e6;
fan_energy = b_values(end); 
disp(['fan_energy(MJ): ', num2str(fan_energy)]);

%figure
plot(t_Q_feed/3600,Q_feed_values,'b');                  % Energy consuption 
hold on;
title('CO2 feed flow velocity');
ylabel('Q_feed (m3)');
xlabel('Duration (hour)');
hold off


%figure
plot(t_Q_feed/3600,cumsum(Q_feed_values.*[t_Q_feed(1),diff(t_Q_feed)]),'b');                  % Energy consuption 
hold on;
title('CO2 feed sum flow ');
ylabel('accumulated_Q_feed (m3)');
xlabel('Duration (hour)');
hold off

x = t_Q_feed / 3600; % hour
diff_t = [t_Q_feed(1), diff(t_Q_feed)]; % Calculate the time difference
[carbonation_duration, idx] = max(x);
max_y = y(idx);
disp(['carbonation_duration(hour): ', num2str(carbonation_duration)]);

num_recorded_Q = size(Q_feed_values,2);
num_recorded_t = size(t, 1);
Q_changing_time_intervals = diff(t_Q_feed);
final_Q_interval = t(num_recorded_t) - t_Q_feed(num_recorded_Q);
final_accumulated_Q_feed = sum(Q_feed_values(1:num_recorded_Q-1).* Q_changing_time_intervals) + Q_feed_values(num_recorded_Q)* (final_Q_interval);
total_CO2_supplied = final_accumulated_Q_feed * pCO2_in *1e5/8.314/T*44/1000; %(in kg)
CO2_total_supplied = total_CO2_supplied;
disp(['CO2_total_supplied(kg):',num2str(CO2_total_supplied)]);


% 参数定义
W_i = 0.0135;        %  kWh/kg
D_sm = 0.015;        % initial particle size, m 

% 计算公式：E_c = W_i * (1/sqrt(D_sp) - 1/sqrt(D_sm))
E_c = 0.01* W_i * (1/sqrt(dp) - 1/sqrt(D_sm)) * SS_total;


% 创建并输出 summary 数据到 Excel
filename = 'BOF_lca_data.xlsx';
summary_data = table(SS_total, CO2_max_stored, CO2_total_stored, CO2_total_stored/SS_total, carbonation_duration, CO2_total_supplied, ...
    fan_energy, CO2_total_stored/CO2max_l, pCO2_in, T, dp, E_c,...
    'VariableNames', {'SS_total_mass_kg', 'CO2_max_stored_per_kgSS', 'CO2_total_stored_kg', 'CO2_total_stored_per_kgSS', ...
    'carbonation_duration_hr', 'CO2_total_supplied_kg', 'fan_energy_MJ', 'carbonation_degree', 'pCO2_in_bar', 'T_K','dp_m','crushing_energy_kWh'});

% 判断文件是否已存在
if isfile(filename)
    writetable(summary_data, filename, 'WriteMode', 'append');
else
    writetable(summary_data, filename);  % 第一次写入带表头
end

disp('Result appended to carbonation_summary_pure.xlsx');

fprintf('Do\tDk\tDco2\tks\tGt\tCCO2_e\tCCO2_in\n');

fprintf('%.10e\t%.10e\t%.10e\t%.10e\t%.10e\t%.10e\t%.10e\n', ...
        Do, Dk, Dco2, ks, Gt, CCO2_e, CCO2_in);

% Export t_ch and t_Diff data to Excel
%output_table = table(t_record, t_ch_record, t_Diff_record, ...'VariableNames', {'Time_s', 't_ch_s', 't_Diff_s'});

%writetable(output_table, 't_ch_t_Diff_output.xlsx');
%disp('t_ch and t_Diff have been exported to t_ch_t_Diff_output.xlsx');

% Event function that used to terminate the ODE, the judgement threshold is CO2max_l
function [value,isterminal,direction] = myEventFcn(t,y)
global CO2max_l n_com;

required_carbonation_degree = 0.90;
CO2_absorbed = y(n_com+1);
value = CO2_absorbed - CO2max_l*required_carbonation_degree;         % Set the value of the event function, in kg 
isterminal = 1;                                                          % Halt integration
direction = 0;                                                           % All directions
if value > 0  
    fprintf('Sum of R exceeds threshold value %f !\n',CO2max_l*required_carbonation_degree);
end
end

% ODE function for n compartments 
function dydt = odegunc_A(t, y)
%global total_pressure Mass_ss Q_feed CCO2_in Q_feed_values t_Q_feed rho_CaO dp V_CO2 Gt Q_out_final recorded_time control_interval CO2_max_stored ks CCO2_e Do L n_com e R_l A;
global ep tp ks0 Ek rp0 pore_coef T_coef_1 T_coef_2 T_coef_0 T min_rp total_pressure Mass_ss Q_feed CCO2_in Q_feed_values t_Q_feed rho_CaO dp V_CO2 Gt Q_out_final recorded_time control_interval CO2_max_stored ks CCO2_e Do L n_com e R_l A;

dydt = zeros(1*n_com+2, 1); % Since there is only 1 compartment, dydt length is 3
R = zeros(n_com,1);
Q_in = zeros(n_com,1);
Q_out = zeros(n_com,1);
Q_reducation = zeros(n_com,1);

T0 = 273.15;

if t > (recorded_time + control_interval)
    if Q_out_final >= 1e-2 * Q_feed
        Q_feed = 0.9* Q_feed;
        control_interval = 10;
    end
    if Q_out_final <= eps
        Q_feed = 1.1* Q_feed;
        control_interval = 10;
    end
    Q_feed_values = [Q_feed_values, Q_feed];
    t_Q_feed = [t_Q_feed, t];
    recorded_time = t;
end

R =[];
delta_p = [];
for j = 1:n_com
    Cco2 = CCO2_in; % CO2 concentration; ignoring impact of pressure change on CCO2
    
    X = y(j); % Reaction conversion
    ks = ks0 * exp(-Ek / (8.314 * T));
    t_ch = (rho_CaO * dp) / (2 * ks * (Cco2 - CCO2_e));

    rp_c1 = T_coef_0*(T/273)^-T_coef_1;
    rp_c2 = 10^pore_coef;
    rp_c3 = 1-(1./(1.+exp(-rp_c2.*(X+rp_c1-1)*2)));
    rp = rp0*(rp_c3+min_rp*(T/T0)^T_coef_2);
    Dk = (2 / 3) * rp * sqrt((8 * 8.314 * T) / (pi * 0.04401)); % Diffusivity, m^2/s

    Dco2 = 0.2020 * exp(-0.3738 ./ (T ./ T0)) .* (T ./ T0) .^ 1.590*1e-4; %m^2/s; unit conversion added
    Do = (ep / tp) * (1 / Dk + 1 / Dco2)^(-1); % Overall diffusivity, m^2/s
    
    t_Diff = (rho_CaO * dp^2) / (24 * Do * (Cco2 - CCO2_e));
    remaining_conversion = max(1 - X, eps);
    dX_dt = 1 / ((2 * t_Diff * (remaining_conversion^(-1/3) - 1)) + (t_ch / 3 * remaining_conversion^(-2/3)));
    dydt(j) = dX_dt;
    R(j) = CO2_max_stored * Mass_ss * dX_dt;

    if j >1 
%        CCO2_in_j = y(2*(j-2)+1);
        Q_reduction(j) = R(j) / 0.044 / Gt;
        Q_in(j) = Q_out(j-1);
        %%%AY edited to avoid negative flow
        Q_out(j) = max(Q_in(j)-Q_reduction(j),eps);
    else
        Q_reduction(j) = R(j) / 0.044 / Gt;
        %%%AY edited to avoid negative flow
        Q_out(j) = max(Q_feed-Q_reduction(j),eps);
        Q_in(j) = Q_feed;
%        CCO2_in_j = CCO2_in;
    end

    if j == n_com
        Q_out_final = Q_out(j);
    end


     % calculate pressure drop delta_p
    air_density = 1.1691;                                  %density of fluid, kg/m3
    gamma = 1.28;
    eta = 0.85*0.95;
    v = Q_in(j)/A;                               % Q_feed unit is cm3/s, but the unit of Q is m3/s. So, times 1e-6 here, v is the flow speed, m/s
    u = 18.37*1e-6;                                        % u is the dynamic viscosity of the fluid, Pa*sec 
    Re = air_density * v * dp / u;
    delta_p(j) = 150 * L/n_com * air_density *v.^2 *(1-e).^2 / (Re * dp *e.^3) +1.75 * L/1e2/n_com * air_density *v.^2 * (1-e) / (dp*e.^3);
end
% Compute dCco2_dt
%dCco2_dt = (Q_feed * (CCO2_in - Cco2) - R / 0.044) / V_CO2;
global t_record t_ch_record t_Diff_record

% Record values at every step
t_record = [t_record; t];
t_ch_record = [t_ch_record; t_ch];
t_Diff_record = [t_Diff_record; t_Diff];



P_in = total_pressure * 1e5;
P_out = P_in + sum(delta_p);
Wg = (1 / eta) * P_in * Q_feed * gamma / (gamma-1) * ((P_out / P_in)^(1-1/gamma) - 1);

% Update ODE equations

dydt(n_com+1) = sum(R); % CO2 absorption amount
dydt(n_com+2) = Wg; % Fan power consumption
end
