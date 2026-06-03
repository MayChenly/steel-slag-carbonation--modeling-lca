%% Model details
% Rate model for leaching of elements
% Influence of H+ using Langmuir-Hinshelwood form
% Surface area evolution of Calcium silicates according to volume change
% Surface area evolution of RO phase by sporulation mechamism
% Sporulation mechanism is solved using population balance models
% PDEs from Population balance model have been solved simultaneously with
% rate equation ODEs after forward difference approximations

%% Update
% Surface area definition for Mg and Fe rich phase, changed from mass
% fraction to atomic fraction.

clc
clear all
global tH pH b m V MWCa xCa xFe xMg rho pH_c C_acid nL r0 d0 nRO_Vslag dslag xRO hL L delt

%% load experimental data
t = 2880;                 % reaction time t in min; ODE integration time [0 to t]

%% Effect of H/S
%H_S_ratio = 7.2*2;  % mmol acid /g solid
initial_pH = 1;

% slag properties
m = 10*1000;              % Weight of slag in g
V = 1*1000;              % Volume of water in L
dslag = 10;          % slag diameter in micro meters  （1e-5 m）
xCa = 0.2816;           % weight fraction of Ca in slag
xFe= 0.2350*0.6;       % weight fraction (soluble) Fe in the slag-is 60% of total
xMg = 0.0585;           % Weight fraction of Mg in the slag
rho = 4070;             % density of slag kg/m3


MWCa = 40.08;           % atomic mass of Ca
MWFe = 55.84;           % atomic weight of Fe
MWMg = 24.305;          % atomic weight of Mg
MWFeO = 71.84;          % molecular weight of FeO
MWMgO = 40.304;         % molecular wright of MgO




Ca_conc_max = m*xCa/MWCa/V; %mol/l

% leaching solution concentration
%C_acid = H_S_ratio*m/V/1000;  % Intial concentration of the acid
%pH_c = -log10(C_acid);  % pH of the solution (concentration and not the activity)
C_acid = 10^(-initial_pH);



% estimated kinetic parameters
k_var=[52.5;10.8931131105590;80.6766914789450/0.685;38.1215982409933/1.579;1.00000000000014e+18;5.65839038285096;5.80000000000000];
%[geo parameter delta; kCa; kFe; kMg; kFeppt; KSC_Fe/Mg]

xRO = (xFe*MWFeO/MWFe + xMg*MWMgO/MWMg); % weight fraction of RO phase in the slag (FeO+MgO)
b = V*MWCa/m/xCa;       % approximate factor at which Ca depth of leaching is changing 

% properties of RO phase globules (spores) in the matrix
d0 = 14e-6;                      % micrometer; diameter of inclusions of RO phase
r0 = 7e-6;                       % micrometer; radius of inclusions of RO phase
nRO_Vslag = xRO/(1/6*pi*d0^3);   % number of particles per unit volume 



%% Sporulation model initial conditions
% discretisation of space domain (radius of RO phase spore)
nL = 500;               % Number of grid points                           
hL = d0*1.2/nL;         % grid spacing    
L = 0:hL:d0*1.2;        % size of the grid 

delt  = min(1,k_var(1)/dslag); % fraction of RO globules exposed initially
d_sigma = hL;                  % standard deviation of RO phase size distribution (monodisperse assumption)

% initial distribution of sporules in solution is F0
fD(1,1:nL+1)= 1/hL/sqrt(2*pi)*exp(-0.5*((L-d0)/hL).^2); % distribution density of RO phase particles in slag matrix
F0(1,1:nL+1)= delt*(m*1e-3/rho*nRO_Vslag)*fD;

y0 = [0 0 0 0 (C_acid) 0 0 0 0]; % inital concentration of species in the solution
% [Ca Fe (II) Mg Feppt H];
y0(10:nL+10)=F0;             % Intial distribution of RO spores in the contact with the solution

%% Integration of rate equations (intial value problem)
options = odeset('Stats','on'); % options for ODE45
[t1,y1] = ode15s(@(tx,y)int_fun(tx,y,k_var),[0 t],y0,options); % ODE45


%% Results from integration
H1 = y1(:,5);       % array of concentrations of acid for times t1

I = (2)*(y1(:,1)+y1(:,2) + y1(:,3))+ (0.5*H1 + 0.5*C_acid)+4.5*y1(:,6);    % Estimation of ionic strenght
g1 = 10.^(-0.5085*(sqrt(I)./(1 + sqrt(I))- 0.3*I)); % activity coefficient for +1 species


%% Plot
figure
ax=gca;
set(gca,'fontsize',16)
hold on
npc=5;
npr=1;
subplot(npr,npc,1)
plot(t1,y1(:,1))
xlabel('Time (min)');
ylabel('Concentration of Ca in solution (M)')

hold on

subplot(npr,npc,2)
plot(t1,y1(:,1)/Ca_conc_max)
xlabel('Time (min)');
ylabel('Extraction percentage of Ca')
hold on

 subplot(npr,npc,3)
% hold on
% plot(t1,-log10(H1.*g1),tH(tH<=t),pH(tH<=t),'*','LineWidth',2)
 plot(t1,-log10(H1.*g1))
 ylabel('pH')

 hold on
subplot(npr,npc,4)
plot(t1,(y1(:,2)+y1(:,6)))
ylabel('Concentration of Fe in solution (M)')

hold on
subplot(npr,npc,5)
plot(t1,y1(:,3))
ylabel('Concentration of Mg in solution (M)')

% 将目标时间设置为20分钟 = 1200秒

Ca_concentration = y1(:,1);
target_time = 20 * 60;  % 单位为秒

% 找到最接近目标时间的索引
[~, idx_time_20min] = min(abs(t1 - target_time));

% 对应时间点的Ca浓度
Ca_at_20min = Ca_concentration(idx_time_20min);

% 输出结果
fprintf('Ca浓度在20分钟（%.1f秒）时为：%.4f\n', t1(idx_time_20min), Ca_at_20min);


%% 将结果写入Excel
output_data = table(m/1000,20, Ca_at_20min, ...
    'VariableNames', {'BOF_steel_slag_kg','Time_min', 'Ca_Concentration_mol_per_L'});
writetable(output_data, 'BOF_Indirect_dissolution_result.xlsx');

%% 将结果写入Excel
output_data = table(m/1000,time_Ca_max, Ca_max, ...
    'VariableNames', {'BOF_steel_slag_kg','Time_min', 'Ca_Concentration_mol_per_L'});
writetable(output_data, 'BOF_Indirect_dissolution_result.xlsx');


