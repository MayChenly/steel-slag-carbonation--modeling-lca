function dydt = int_fun(t,y, k_var)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
% y = [Ca Fe Mg H]
global tH pH b V m rho xMg xFe C_acid nRO_Vslag nL d0 dslag hL L delt xCa


H = y(5);
OH = 1e-14/H;


I = (2)*(y(1)+y(2)+y(3)) + (0.5*C_acid+ 0.5*H) + 4.5*y(6);    % Estimation of ionic strenght
g1 = 10^(-0.5085*(sqrt(I)/(1 + sqrt(I))- 0.3*I)); % activity coefficient for +1 species
g2 = 10^(-0.5085*4*(sqrt(I)/(1 + sqrt(I))- 0.3*I)); % activity coefficient for +2 species
g3 = 10^(-0.5085*9*(sqrt(I)/(1 + sqrt(I))- 0.3*I)); % activity coefficient for +2 species

% Fe speciation (equilibrium constants from Aqion PRO)
K1 = 10^(11.30);    %Fe(3+) + OH- <-kk1> Fe(OH)(2+)
K2 = 10^(9.965);    %Fe(OH)(2+) + OH- <-kk2> Fe(OH)2(+)
K3 = 10^(6.808);    %Fe(OH)2(+) +OH- <-kk3> Fe(OH)3
KSP = 10^(-13.581); % Solubility product of FeOOH Fe(OH)3 <-> FeOOH(s)
YY = (1 + K1*OH*g1 +K1*K2*OH^2*g1^2+K1*K2*K3*OH^3*g1^3);

Fe3 = y(6)/YY;
FeOH = K1*Fe3*g3*OH*g1;
FeOH2 = K1*K2*Fe3*g3*OH^2*g1^2;
FeOH3 = K1*K2*K3*Fe3*g3*OH^3*g1^3;

I = (2)*(y(1)+y(2)+y(3) + FeOH) + (0.5*C_acid+ 0.5*H + 0.5*FeOH2) + 4.5*Fe3;    % Estimation of ionic strenght
g1 = 10^(-0.5085*(sqrt(I)/(1 + sqrt(I))- 0.3*I)); % activity coefficient for +1 species
g2 = 10^(-0.5085*4*(sqrt(I)/(1 + sqrt(I))- 0.3*I)); % activity coefficient for +2 species
g3 = 10^(-0.5085*9*(sqrt(I)/(1 + sqrt(I))- 0.3*I)); % activity coefficient for +2 species


% rate parameters
kS0 = k_var(2); % (lumped) rate ocnstant for Ca leaching
kFe = k_var(3); % (lumped) rate constant for Fe leaching
kMg = k_var(4); % (lumped) rate constant for Mg leaching
kox = k_var(5);% (lumped) rate constant for Fe oxidation    
KSCa = 5.8;     % Langmuir constant for Ca phase
KSC = k_var(6)*0+5.6; % Langmuir constant for Fe phase
KSC_Mg = KSC;   % Langmuir constant for Mg phase
kppt = 1e7;    % Rate of precipitation

%% Rate of calcium leaching
X =1.25*b*y(1);  % extent of Ca extraction
%dCadt = kS0*(1-X)/V*(m/dslag)*(g1*H)/(1 + KSCa*g1*H); % (mol/L) rate of change in Ca concentration
%total surface area of original slag particles
%AY
SCa0 = m*1e-3/rho*(6/(dslag/1e6));
SCa0_ = m/dslag;
dCadt = kS0*(1-X)/V*SCa0*(g1*H)/(1 + KSCa*g1*H); % (mol/L) rate of change in Ca concentration

%% sporulation model by finite differences

dVslagdt = -dCadt*V*(40.08*1e-3)/xCa/rho;   % rate of change in slag volume
d_sigma = hL;                  % standard deviation of RO phase size distribution (monodisperse assumption)


yMg = xMg/24.3/(xMg/24.3*2 + xFe/56*2); %Mg/(Mg+O+Fe+O)=Mg/(2*Mg+2*Fe)
yFe = xFe/56/(xMg/24.3*2 + xFe/56*2);%Fe/(Mg+O+Fe+O)=Fe/(2*Mg+2*Fe)


dnRO = (1-delt)*nRO_Vslag*(-dVslagdt)/d_sigma/sqrt(2*pi)*exp(-0.5*((L-d0)/d_sigma).^2); % generation of RO sporules with Ca dissolution
dD_RO = -2*(kMg*yMg+kFe*yFe)/rho/(yMg+yFe)/1000*((H*g1))/(1 + KSC*(g1*H)); % rate of change in RO particle diamater

F = y(10:nL+10);                      % distribution function F(D,t)
Fx = F(2:end);                      % forward elements for difference F(D+dD,t)
Fx(end+1) = 2*Fx(end)-F(end-1);     % assigning nth term assuming equal +/-ve slopes

dF = -1/hL*dD_RO*(Fx - F) + dnRO';  % Evaluation of distribution for next time step;


SA_RO = pi()*trapz(L,F'.*L.^2);
SA_Mg = yMg/(yMg+yFe)*SA_RO;
SA_Fe = yFe/(yMg+yFe)*SA_RO;

dMgdt = kMg*SA_Mg/24.3/V*((H*g1))/(1+ KSC_Mg*(g1*H)); % (mol/L) Rate of leaching of Mg
dFe2dt = kFe*SA_Fe/55.84/V*(H*g1)/(1 + KSC*(g1*H));    % (mol/L) rate of leaching of Fe

Fe_precipitation_rate = kox*(y(2))*g2*(OH*g1)^2;

dFedt = dFe2dt - Fe_precipitation_rate;   % net rate of Fe(II) release after Fe(III) precipitation

if FeOH3 >0
SI = log10(FeOH3/KSP);
else
    SI=-1;
end

dFe3dt = Fe_precipitation_rate-kppt*FeOH3*heaviside(SI);



kk1 = 1e10;
kk2 = 1e5;
kk3 = 1e5;


% dFe3dt = kox*(y(2))*g2*(OH*g1)^2 - kk1*(Fe3)*g3*OH*g1 + kk1/K1*(FeOH)*g2;
dFeOHdt = kk1*(Fe3)*g3*OH*g1 - kk1/K1*(FeOH)*g2 - kk2*(FeOH)*g2*OH*g1 + kk2/K2*(FeOH2)*g1;
dFeOH2dt = kk2*(FeOH)*g2*OH*g1 - kk2/K2*(FeOH2)*g1 - kk3*(FeOH2)*g1*OH*g1 + kk3/K3*FeOH3;
dFeOH3dt = kk3*(FeOH2)*g1*OH*g1 - kk3/K3*FeOH3 - kppt*FeOH3*heaviside(SI);


% dFedt_ppt = kppt*(y(2))*g2*(OH*g1)^2;        % rate of precipitation of Fe(III)
dFedt_ppt = kppt*FeOH3*heaviside(SI);
 

dFe3plus = -dFe3dt/YY^2*(K1+2*K1*K2*OH+3*K1*K2*K3*OH^2);
dH = (-2*(dCadt + dFedt + dMgdt))/(1+ (3*dFe3plus-1+2*K1*dFe3plus*OH+2*K1*Fe3 + K1*K2*dFe3plus*OH^2+2*K1*K2*Fe3*OH)*(-OH/H)); 


% dH = (-2*(dCadt + dFedt + dMgdt + dFeOHdt)-3*dFe3dt -dFeOH2dt)/(1+1e-14/H^2); 
% H1 = fzero(@(H2)(H2 - 1e-14/H2 - C_acid + 2*(y(1)+y(2) +y(3)+y(7))+3*y(6)+y(8)),1e-4); 
% dH = H1-H;
dydt(1:9,1) = [dCadt; dFedt; dMgdt; dFedt_ppt; dH; dFe3dt; dFeOHdt; dFeOH2dt; dFeOH3dt];
dydt(10:nL+10,1)= dF;

end

