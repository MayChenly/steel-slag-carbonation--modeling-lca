clear all

global Enhancement_factor Na Cl kLa VR VL VG KMgCO3 KCaCO3 KHCO3 KCO3 Cl Na SO4 K Br Increase_in_Cl Na_before_precipitation Cl_before_precipitation number_of_seeds CO2aq_all HCO3_all CO3_all TIC_seawater_after_degassing Ca_after_dissolution Omega_CaCO3_all Omega_MgCO3_all Omega_CaCO3_conc Omega_MgOH2_all
global feed_inert_fraction Q_feed VG Q_out;

% ******************************************
% main parameters for adjustment *******************
data = readmatrix('C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\BOF\BOF_Indirect_dissolution_result.xlsx');

Simulation_length = 100 ; %hours
CO2_purity = 0.1;
% 读取第二列数据（假设全部读取）
Ca_from_leaching = data(:, 3); % mol/l
% ******************************************

Cl_from_leaching = 0.1; %in mol/l, based on pH 1 acid
Na_from_BPMED = 0.1; %in mol/l, same as Cl from leaching


Cl = Cl_from_leaching/2;    % diluted by merging leaching elluent and base solution from BPMED 
Na = Na_from_BPMED/2;    % diluted
Ca = Ca_from_leaching/2;    % diluted

feed_inert_fraction = 1 - CO2_purity;
Mg = 0.0;    % M
SO4 = 0;    % M
Ca = Ca_from_leaching/2;    % diluted
K = 0;     % M
TIC = 1e-10;     % negligible small amount
Br = 0;     % M
B = 0;     % M
Sr = 0;     % M +2
F = 0;     % M -1

VL = 2*1000; % (L) reactor solution volume
target_precipitation_time = 1; %hours
total_Ca = VL*Ca_from_leaching; %mol
CO2_feed_rate_estimated = total_Ca/target_precipitation_time;
Q_feed = CO2_feed_rate_estimated/(1-feed_inert_fraction)*8.314*300/1.013e5; %m3/hour
Q_out = Q_feed; %initialise

global recorded_time control_interval t_Q_feed Q_feed_values;
recorded_time = 0;
control_interval = 0.0001; %in hours
Q_feed_values = [Q_feed];
t_Q_feed = [0];

Cl_molar_mass = 35.45;          % 氯离子 (Cl⁻)
Na_molar_mass = 22.99;          % 钠离子 (Na⁺)
Mg_molar_mass = 24.31;          % 镁离子 (Mg²⁺)
SO4_molar_mass = 96.06;         % 硫酸根离子 (SO₄²⁻)
Ca_molar_mass = 40.08;          % 钙离子 (Ca²⁺)
K_molar_mass = 39.10;           % 钾离子 (K⁺)
Br_molar_mass = 79.90;          % 溴离子 (Br⁻)
B_molar_mass = 10.81;           % 硼 (B)
Sr_molar_mass = 87.62;          % 锶离子 (Sr²⁺)
F_molar_mass = 19.00;           % 氟离子 (F⁻)


% Calculation of dissociation constant at different temperature and salinity
T = 298; % K, Temperature *************************************************
S = 35; % Salinity ********************************************************
pK1_0 = -126.35048 + 6320.813/T + 19.568224*log(T); % Dissociation constant when salinity is 0; https://www.sciencedirect.com/science/article/pii/S0304420305001921
pK2_0 = -90.18333 + 5143.692/T + 14.613358*log(T);
A1 = 13.4191*S^0.5 + 0.0331*S - (5.33e-5)*(S^2);
B1 = -530.123*S^0.5 - 6.103*S;
C1 = -2.0695*S^0.5;
A2 = 21.0894*S^0.5 + 0.1248*S - (3.687e-4)*(S^2);
B2 = -772.483*S^0.5 - 20.051*S;
C2 = -3.3336*S^0.5;
pK1_S = pK1_0 + A1 + B1/T + C1*log(T); % Dissociation constant when salinity is S
pK2_S = pK2_0 + A2 + B2/T + C2*log(T);
K1 = 10^(-pK1_S);
K2 = 10^(-pK2_S);

KHCO3 = K1;
KCO3 = K2;

KBOH4 = 5.8e-10; % https://pubchem.ncbi.nlm.nih.gov/compound/Boric-Acid#section=pH

syms C_H C_OH CO2aq_0 CO3 HCO3 BOH3 BOH4_ion
eqnsac=[log10(C_H) + log10(C_OH) == -14,
    TIC == (CO2aq_0 + CO3 + HCO3),
    (C_H) * HCO3 == KHCO3 * CO2aq_0,
    (C_H) * CO3 == KCO3 * HCO3,
    B == BOH3 + BOH4_ion,
    (C_H) * BOH4_ion == KBOH4 * BOH3, %????
    ((C_H) + Na + 2*Mg + 2*Ca + K + 2*Sr) - (C_OH + HCO3 + 2*CO3 + Cl + 2*SO4 + Br + BOH4_ion + F)==0];

initial_guesses = [
    10^(-8);        % Initial guess for C_H ([H+])
    10^(-(14-8));       % Initial guess for C_OH ([OH-])
    0.1*TIC;        % Initial guess for CO2aq (mol/L)
    0.7*TIC;        % Initial guess for CO3 ([CO3^2-])
    0.2*TIC;         % Initial guess for HCO3 ([HCO3^-])
    0;  % Initial guess for BOH3
    B % Initial guess for BOH4_ion
];

ranges = [
    1e-14, 1;   % C_H_basic 
    1e-14, 1;   % C_OH_basic 
    0, TIC;   % CO2aq_basic 
    0, TIC;   % CO3_basic 
    0, TIC;   % HCO3_basic 
    0, B;       % BOH3_basic 
    0, B        % BOH4_ion_basic 
];

vars=[C_H,C_OH,CO2aq_0,CO3,HCO3,BOH3,BOH4_ion];

[int_C_H,int_C_OH,int_CO2aq,int_CO3,int_HCO3,int_BOH3,int_BOH4_ion]=vpasolve(eqnsac,vars,ranges); 

int_C_H;
int_C_OH;
int_CO2aq;
int_CO3;
int_HCO3;
int_BOH3;
int_BOH4_ion;

pH_initial = -log10(int_C_H);

% CO2 capture and precipitation --------------------------------------------------------------------------
disp('CO2 capture and precipitation');

Enhancement_factor = 50; % for CO2 dissolution at alkaline environment

% 
logC_H_0 = -double(pH_initial);
logC_OH_0 = -(14-double(pH_initial));
Mg_0 = Mg;
Ca_0 = double(Ca);
TIC_0 = double(int_CO2aq + int_HCO3 + int_CO3);

area_0 = 1; % initial area  m^2/L  **************************************
number_of_seeds = 10^5 ;  % **************************************
D_0 = (area_0/number_of_seeds/pi)^0.5 ; %m; % initial partical diameter  m  **************************************
MgOH2_0 = 0;
MgCO3_0 = 0;
CaCO3_0 = 0;

%aa = ((10^logC_H_0) + Na_before_precipitation + 2*Mg + 2*Ca + K) - (10^logC_OH_0 + HCO3_0 + 2*CO3_0 + Cl_before_precipitation + 2*SO4 + Br)
input_CO2g_mol_frac = 1.013e5/8.314/300 * (1-feed_inert_fraction);

c0 = [logC_H_0, logC_OH_0, Mg_0, Ca_0, TIC_0, area_0, D_0, MgOH2_0, MgCO3_0, CaCO3_0, input_CO2g_mol_frac];
disp(length(c0))

%   C_H  C_OH   Mg    Ca    TIC   area   D   MgOH2 MgCO3 CaCO3  output_CO2
M = [0     0     0     0     0     0     0     0     0     0    0
     0     0     0     0     0     0     0     0     0     0    0
     0     0     1     0     0     0     0     0     0     0    0
     0     0     0     1     0     0     0     0     0     0    0
     0     0     0     0     1     0     0     0     0     0    0
     0     0     0     0     0     1     0     0     0     0    0
     0     0     0     0     0     0     0     0     0     0    0
     0     0     0     0     0     0     0     1     0     0    0
     0     0     0     0     0     0     0     0     1     0    0
     0     0     0     0     0     0     0     0     0     1    0
     0      0   0       0   0       0   0       0   0       0   1];


Number_of_points_to_save = 5001;


Reporting_interval = Simulation_length/ (Number_of_points_to_save-1);

Time_points_for_reporting = 0: Reporting_interval: Simulation_length;

Tspan = Time_points_for_reporting;

%Tspan = [0 0.05]; % Simulation time span (hour)
options = odeset('MaxStep', 1e-3,'Mass',M,'RelTol',1e-2,'AbsTol',1e-3);
[t, y] = ode15s(@(t,y) model_equations2(t,y), Tspan, c0, options);


% diagrams
% 找到 y(:,10) 最大值以及第一次达到最大值的时间
[peakVal, peakIdx] = max(y(:,10));
peakTime = t(peakIdx);

figure;
plot(t, y(:,10));
xlabel('Time (h)');
ylabel('CaCO3 (M)');
CaCO3_concentration = y(:,10);
[CaCO3_max, idx_CaCO3_max] = max(CaCO3_concentration);
time_CaCO3_max = t(idx_CaCO3_max);

fprintf('Ca浓度首次达到最大值时的浓度为: %.6f mol/L\n', CaCO3_max);
fprintf('对应时间为: %.2f 小时\n', time_CaCO3_max);

newCol1 = CaCO3_max;
newCol2 = time_CaCO3_max; 
newCol3 = Q_feed; 
new_data = [newCol1, newCol2, newCol3];
new_data_cell = num2cell(new_data);

new_title = {'CaCO3_Concentration_molperL', 'precipitation_time_h', 'Q_feed_m3_perh'};

[~,~,orig_all] = xlsread('C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\BOF\BOF_Indirect_dissolution_result.xlsx', 'Sheet1');

new_all = [
    [orig_all(1,:), new_title];   % 第一行：标题
    [orig_all(2,:), new_data_cell]     % 第二行：数据
];

xlswrite('C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\BOF\BOF_Indirect_dissolution_result.xlsx', new_all, 'Sheet1', 'A1');

% Model equations
function dydt = model_equations2(t, y)

global Enhancement_factor Na Cl kLa VR VL KMgCO3 KCaCO3 KHCO3 KCO3 SO4 K Br Na_before_precipitation Cl_before_precipitation number_of_seeds CO2aq_all HCO3_all CO3_all Omega_CaCO3_all Omega_MgCO3_all Omega_CaCO3_conc Omega_MgOH2_all

global feed_inert_fraction Q_feed VG;

global recorded_time control_interval Q_out Q_feed_values t_Q_feed

gas_total_conc = 1.013e5/8.314/300;


%adjust Q_feed
if t > (recorded_time + control_interval)
    CCO2_out = y(11);
    if CCO2_out * Q_out >= 0.05 * gas_total_conc * Q_feed *(1-feed_inert_fraction)
        Q_feed = 1* Q_feed;
        control_interval = 0.001;
    end
    Q_feed_values = [Q_feed_values, Q_feed];
    t_Q_feed = [t_Q_feed, t];
    recorded_time = t;
end


% kla calculation
height = 1;% (m) height of reactor
liquid_volume = 1;% (m^3) liquid volume of reactor
QG_h = Q_feed; %(m^3/h) refers to volumetric gas flow rate
N_rpm = 1 ;%(rpm) refers to impeller speed **************************
rho_L = 1000;% kg/m^3 Liquid densaity
uL = 0.00089;% Pa s Liquid viscosity at 25C	https://wiki.anton-paar.com/uk-en/water/
g =9.80665;%m/s^2  Acceleration gravity

D_inside = 2*(liquid_volume/height/3.14)^0.5;% m diameter for inside of reactor
D_impeller = D_inside/3;% m diameter for impeller   Di = 0.2*D (see the reference by Yawalkar, Table 3)
D_impeller_width = 0.2*D_impeller; %Di = 0.2*D (see the reference by Yawalkar, Table 3)
N = N_rpm/60;%(rev s-1) refers to impeller speed
QG = QG_h/3600;  %(m^3/s) refers to volumetric gas flow rate
vG = QG/(3.14*(D_inside/2)^2); %(m s-1) means gas velocity

Ncd = (4*((QG)^0.5)*D_inside^0.25)/D_impeller^2; %(rev s-1) refers to the minimum impeller speed for complete suspension of all the solid particles in stirred tank reactors
kLa_s = 6.48*(N/Ncd)^1.44*vG^1.12; % s^-1
kLa = kLa_s*3600; % h^-1
ReL = rho_L*N*D_impeller^2/uL;
FrL = D_impeller*N^2/g;
Np = min(19.5*ReL^(-0.3),24*(ReL*FrL)^(-1/3));
P0 = rho_L*N^3*D_impeller^5*Np ;%Power input in absence of gas
Pg = P0*0.1*(QG/(N*liquid_volume))^(-0.25)*(N^2*D_impeller^4/(g*D_impeller_width*liquid_volume^(2/3)))^(-0.2); % W Power consumption
epsilon_G = (1.98*vG/(1+40.9*vG))*(Pg/liquid_volume)^0.21;% Gas holdup
epsilon_L = 1-epsilon_G;

VR = VL/(1-epsilon_G); % (L)
VG = VR*epsilon_G; % (L)


logC_H = y(1);
logC_OH = y(2);
Mg = y(3);
Ca = y(4);
TIC = y(5);
area = y(6);
D = y(7);
MgOH2 = y(8);

k1 = KHCO3;
k2 = KCO3;
denominator = 1 + (k1 / (10^logC_H)) + (k1 * k2) / ((10^logC_H)^2);
CO2aq = TIC / denominator;
HCO3 = (k1 * CO2aq) / (10^logC_H);
CO3 = (k2 * HCO3) / (10^logC_H);

pH =  -logC_H; %
Kw =   1*10^-14  ; %
k_prec_MgCO3 = 4.1 * 10^-18 * 10000 * 3600; % MgCO3  mol/m2/h 25C  https://www.sciencedirect.com/science/article/pii/S0016703709004499#:~:text=At%20100%20%C2%B0C%20magnesite,index%20with%20respect%20to%20magnesite.
%k_prec_CaCO3 =     ; % mol/m2/h 25C (Applied different method to estimate precipitation rate of CaCO3)
rho_MgCO3 = 2.96 * 1000000; %g/m³
rho_CaCO3 = 2.71 * 1000000 ; %
rho_MgOH2 = 2.3446 * 1000000 ; %
mol_mass_MgCO3 = 84.3139; %g/mol
mol_mass_CaCO3 = 100.0869; % g/mol
mol_mass_MgOH2 = 58.32; % g/mol
% -------------- pH 8 T 25C PHREEQC-----------------
Mg_activity_coefficient =  1.32/5.273 ; % 
Ca_activity_coefficient =  2.347/10.3 ; % 
CO3_activity_coefficient = 5.341/62.78 ; % 
OH_activity_coefficient = 9.939/18.95 ; % 
% -------------- pH 11.2 T 25C PHREEQC-----------------

if Mg<0
    xxx=0;
end
Mg_activity = Mg * Mg_activity_coefficient; %
Ca_activity = Ca * Ca_activity_coefficient; %
CO3_activity = CO3 * CO3_activity_coefficient; %
OH_activity = 10^logC_OH * OH_activity_coefficient; %
KMgCO3 = 10^(-8.04); % Mg https://www.sciencedirect.com/science/article/pii/S0009254105000161#tbl2
KCaCO3 = 10^(-8.42); % https://www.sciencedirect.com/science/article/pii/S0021979706011830?via%3Dihub
HCO2_aq_g = 0.83; %henry constant for CO2, (-) Caq/Cgas  https://en.wikipedia.org/wiki/Henry%27s_law
%Concentration_CO2_provided = 0.000015;% mol/L  ********************************************************


KCaCO3_for_concentration = 4.39e-7; % https://www.sciencedirect.com/science/article/pii/S1385894722008300?via%3Dihub

% - pH值变化模拟
dlogC_Hdt = logC_H + logC_OH - log10(Kw); % y(1)
dlogC_OHdt = (10.^logC_H + Na + 2*Mg + 2*Ca + K) - (10.^logC_OH + HCO3 + 2*CO3 + Cl + 2*SO4 + Br);  % y(2)

% - omega与沉淀速率变化模拟
Omega_MgCO3 = (Mg_activity .* CO3_activity )/KMgCO3;  % 需修改为使用activity???
Omega_CaCO3 = (Ca_activity .* CO3_activity )/KCaCO3;
Omega_CaCO3_concentration = (Ca .* CO3 )/KCaCO3_for_concentration;

r_aq = double(Ca_activity./CO3_activity); % activity ratio


kg_CaCO3 = 7.45e-6 * 60; % mol/m^2/hour https://www.sciencedirect.com/science/article/pii/S0021979706011830?via%3Dihub#bib024
CaCO3_growth_rate = kg_CaCO3 * (Omega_CaCO3.^0.5 - 1)^2 ; 

if Omega_CaCO3 >= 1
    r_prec_CaCO3 = CaCO3_growth_rate; % ??
else
    r_prec_CaCO3 = 0; %
end

if Omega_MgCO3 >= 1
    r_prec_MgCO3 = (k_prec_MgCO3) * ((Omega_MgCO3)-1)^2; % ??
else
    r_prec_MgCO3 = 0; %
end

% - 在沉淀反应器中加入Mg(OH)2的沉淀模拟

%AC_OH = 9.934e-5 / 10e-4;
%OH_activity = AC_OH * 10^(logC_OH);

%KMgOH2 = 1.5*10^(-11);  %https://owl.oit.umass.edu/departments/Chemistry/appendix/ksp.html
%KMgOH2 = 1.8*10^(-11);  %https://www.chm.uri.edu/weuler/chm112/refmater/KspTable.html
KMgOH2 = 5.61*10^(-12); %https://en.wikipedia.org/wiki/Magnesium_hydroxide  and  https://www.sciencedirect.com/science/article/pii/S0254058415301887
%KMgOH2 = 5.67*10^(-10);  %Estimated, in seawater

MgOH2_molecular_density = rho_MgOH2 / mol_mass_MgOH2; % mol/m^3
if Mg_activity .* (OH_activity)^2 / KMgOH2 >= 1
    omega_MgOH2_seawater_calc = Mg_activity .* (OH_activity)^2 / KMgOH2 - 1; % consider the ionic strength https://www.sciencedirect.com/science/article/pii/S0254058415301887
else
    omega_MgOH2_seawater_calc = 0;
end
kg_MgOH2 = 2.51e-10 ; % m/s growth rate https://pubs.acs.org/doi/10.1021/acs.cgd.2c01179
MgOH2_linear_growth_rate = kg_MgOH2 * omega_MgOH2_seawater_calc^1.001 * 3600; % m/hour
% MgOH2_linear_growth_rate_mmpermin = MgOH2_linear_growth_rate * 1000 / 60; % mm/min

if omega_MgOH2_seawater_calc >= 1
    r_prec_MgOH2 = MgOH2_linear_growth_rate * MgOH2_molecular_density; % mol m^-2 h^-1; % mol/hour
else
    r_prec_MgOH2 = 0; % mol m^-2 h^-1; % mol/hour
end

% - 反应器内钙镁离子浓度变化模拟
dMgdt = - area * (r_prec_MgCO3 + r_prec_MgOH2); % y(3)
dCadt = - area * r_prec_CaCO3; % y(4)

% - bubbling二氧化碳供给模拟
Concentration_CO2_provided = y(11);
r_g_L = Enhancement_factor * kLa *(Concentration_CO2_provided*HCO2_aq_g/1000 - CO2aq); %(M/h) ?????????????????????

if feed_inert_fraction >0
    Q_out  = Q_feed*feed_inert_fraction*gas_total_conc/(gas_total_conc - Concentration_CO2_provided);
    dCO2g_out_dt = (Q_feed*gas_total_conc*(1-feed_inert_fraction) - r_g_L*VR - Concentration_CO2_provided*Q_out)/VG;
else
    dCO2g_out_dt = 0;
end


if TIC > 0
    dTICdt = r_g_L*(VR/VL) - area *(r_prec_MgCO3 + r_prec_CaCO3); % y(5) %
else
    dTICdt = r_g_L*(VR/VL); % y(5) %
end

% - seeding与沉淀反应面积变化模拟 (碳酸镁碳酸钙共用同一个表面积)
dareadt = ((4/rho_MgCO3) / D) * (r_prec_MgCO3 * area /number_of_seeds * mol_mass_MgCO3) *number_of_seeds...
    + ((4/rho_CaCO3) / D) * (r_prec_CaCO3 * area /number_of_seeds * mol_mass_CaCO3) *number_of_seeds...
    + ((4/rho_MgOH2) / D) * (r_prec_MgOH2 * area /number_of_seeds * mol_mass_MgOH2) *number_of_seeds; % y(6) %  m^2/L
dDdt = D - (area/number_of_seeds/pi)^0.5; % y(7) % diameter m

% - 碳酸离子分布随时间变化，基于pH与离子活度
dMgOH2dt = r_prec_MgOH2 * area; % y(8) M  
dMgCO3dt = r_prec_MgCO3 * area; % y(9) M   这里KHCO3等直接使用的开始计算的35盐度的值
dCaCO3dt = r_prec_CaCO3 * area; % y(10) M

CO2aq_all = [CO2aq_all; CO2aq];
HCO3_all = [HCO3_all; HCO3];
CO3_all = [CO3_all; CO3];
Omega_CaCO3_all = [Omega_CaCO3_all; Omega_CaCO3];
Omega_MgCO3_all = [Omega_MgCO3_all; Omega_MgCO3];
Omega_MgOH2_all = [Omega_MgOH2_all; omega_MgOH2_seawater_calc];
Omega_CaCO3_conc = [Omega_CaCO3_conc; Omega_CaCO3_concentration];


% Pack the derivatives into a column vector
dydt = [dlogC_Hdt; dlogC_OHdt; dMgdt; dCadt; dTICdt; dareadt; dDdt; dMgOH2dt; dMgCO3dt; dCaCO3dt; dCO2g_out_dt];

end


