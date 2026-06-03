clear all
filename = 'EAF_lca_data';
data = readtable(filename, 'VariableNamingRule', 'preserve');


% Fixed variables
scenario = 2;
CO2_concentration = 1; % bar
BOF_mass = data.('SS_total_mass_kg'); %kg
universial_gas_constant_R = 8.31 ; % J/mol/k
CO2_molar_mass = 44; % g


% Adjust variables
country_emission_factor = 0.21741 ; % kgco2/kwh
CO2_gas_product_DAC = 1 ; % ton
tare_weight = 0.4212 ; % ton
distance_one_way = 0:500:3000; % km
road_trailer_emission_factor = 0.112; % kg co2 per ton km
electrcity_truk = 0.921; %kwh/km
total_weight = (CO2_gas_product_DAC + 2 * tare_weight); % ton
fan_energy = data.('fan_energy_MJ');
carbonation_duration = data.('carbonation_duration_hr');
crush_energy = data.('crushing_energy_kWh');
CO2_total_supplied = data.('CO2_total_supplied_kg');
CO2_total_stored = data.('CO2_total_stored_kg');

% DAC capture

% dissel+DAC option1
conversion_ratio  = 1000 / BOF_mass ;  % conversion BOF mass in chamber to 1 tonne

o1_CO2_removed_from_air = 0.769231 ; % tonne
o1_electrcity_for_1_bar_CO2 = 152.8836 ; % kwh 1 bar
naturegas_for_1_bar_CO2 = 1121.796 ; % kwh 1 bar
o1_E_DAC = o1_electrcity_for_1_bar_CO2 * country_emission_factor ; %kg
E_liquefaction = 89 * country_emission_factor; %kg
E_vaporisation = 5.4 * country_emission_factor; % kg
E_transportation = total_weight * distance_one_way * 2 * road_trailer_emission_factor ; %kg
o1_R_part1 = o1_E_DAC + E_liquefaction + E_vaporisation + E_transportation; 
input_ratio = CO2_total_supplied / 1000 * conversion_ratio;
E_transportation_input_ratio = E_transportation * input_ratio;


o1_E_part1 = o1_R_part1 * input_ratio ;
E_crushing_chamber = crush_energy * country_emission_factor ; % kg
E_fan_chamber = fan_energy/3.6 * country_emission_factor ; % kg
E_escape_chamber = CO2_total_supplied - CO2_total_stored ; % kg
o1_R_DAC_chamber = CO2_total_supplied * o1_CO2_removed_from_air; %kg

E_crushing = E_crushing_chamber * conversion_ratio;
E_fan = E_fan_chamber * conversion_ratio;
E_escape = E_escape_chamber * conversion_ratio;
o1_R_DAC = o1_R_DAC_chamber * conversion_ratio;

o1_R_total = o1_E_part1 + E_crushing + E_fan + E_escape - o1_R_DAC;
CO2_stored_tonneBOF = CO2_total_stored *conversion_ratio;

LCA11 = table(distance_one_way', E_transportation_input_ratio', o1_R_total', 'VariableNames', {'Distance (km)', 'transportation (kg)','o1_R_total (kg)'});
LCA12 = table(scenario',CO2_stored_tonneBOF',o1_E_DAC * input_ratio',E_liquefaction*input_ratio',E_vaporisation*input_ratio',E_crushing',E_fan',E_escape',o1_R_DAC * (-1)', ...
    'VariableNames', {'Scenario','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)','vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
LCA12_expanded = repmat(LCA12, height(LCA11), 1);
LCA1 = [LCA12_expanded,LCA11];

% dissel+DAC option2

o2_CO2_removed_from_air = 1 ; % tonne
o2_electrcity_for_1_bar_CO2 = 7220 /3.6; % kwh 1 bar
electrcity_for_005_bar_CO2 = 3962.230051 / 3.6; % kwh 0.05 bar
electrcity_for_010_bar_CO2 = 4552.583826 / 3.6 ; % kwh 0.1 bar
electrcity_for_015_bar_CO2 = 4907.685607 / 3.6 ; % kwh 0.15 bar
electrcity_for_020_bar_CO2 = 5167.014105 / 3.6 ; % kwh 0.2 bar

o2_E_DAC = o2_electrcity_for_1_bar_CO2 * country_emission_factor; %kg
o2_R_part1 = o2_E_DAC + E_liquefaction + E_vaporisation + E_transportation; 
o2_E_part1 = o2_R_part1 * input_ratio ;
o2_R_DAC_chamber = CO2_total_supplied * o2_CO2_removed_from_air; %kg
o2_R_DAC = o2_R_DAC_chamber * conversion_ratio;
o2_R_total = o2_E_part1 + E_crushing + E_fan + E_escape - o2_R_DAC;

LCA13 = table(distance_one_way', E_transportation_input_ratio', o2_R_total', 'VariableNames', {'Distance (km)', 'transportation (kg)','o2_R_total (kg)'});
LCA14 = table(scenario',CO2_stored_tonneBOF',o2_E_DAC*input_ratio',E_liquefaction*input_ratio',E_vaporisation*input_ratio',E_crushing',E_fan',E_escape',o2_R_DAC * (-1)', ...
    'VariableNames', {'Scenario','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)','vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
LCA14_expanded = repmat(LCA14, height(LCA13), 1);
LCA2 = [LCA14_expanded,LCA13];


%  EV+DAC option1
e_E_transportation = distance_one_way * 2 * electrcity_truk * country_emission_factor; %kg
e1_R_part1 = o1_E_DAC + E_liquefaction + E_vaporisation + e_E_transportation; 
e_E_transportation_input_ratio = e_E_transportation * input_ratio;


e1_E_part1 = e1_R_part1 * input_ratio ;
e1_R_DAC_chamber = CO2_total_supplied * o1_CO2_removed_from_air; %kg
e1_R_DAC = e1_R_DAC_chamber * conversion_ratio;
e1_R_total = e1_E_part1 + E_crushing + E_fan + E_escape - e1_R_DAC;

LCA15 = table(distance_one_way', e_E_transportation_input_ratio', e1_R_total', 'VariableNames', {'Distance (km)', 'transportation (kg)','e1_R_total (kg)'});
LCA16 = table(scenario',CO2_stored_tonneBOF',o1_E_DAC * input_ratio',E_liquefaction*input_ratio',E_vaporisation*input_ratio',E_crushing',E_fan',E_escape',e1_R_DAC * (-1)', ...
    'VariableNames', {'Scenario','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)','vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
LCA16_expanded = repmat(LCA16, height(LCA15), 1);
LCA3 = [LCA16_expanded,LCA15];


%  EV+DAC option2
e2_R_part1 = o2_E_DAC + E_liquefaction + E_vaporisation + e_E_transportation; 
e2_E_part1 = e2_R_part1 * input_ratio ;
e2_R_DAC_chamber = CO2_total_supplied * o2_CO2_removed_from_air; %kg
e2_R_DAC = e2_R_DAC_chamber * conversion_ratio;
e2_R_total = e2_E_part1 + E_crushing + E_fan + E_escape - e2_R_DAC;

LCA17 = table(distance_one_way', e_E_transportation_input_ratio', e2_R_total', 'VariableNames', {'Distance (km)', 'transportation (kg)','e2_R_total (kg)'});
LCA18 = table(scenario',CO2_stored_tonneBOF',o2_E_DAC * input_ratio',E_liquefaction*input_ratio',E_vaporisation*input_ratio',E_crushing',E_fan',E_escape',e2_R_DAC * (-1)', ...
    'VariableNames', {'Scenario','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)','vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
LCA18_expanded = repmat(LCA18, height(LCA17), 1);
LCA4 = [LCA18_expanded,LCA17];


output_filename = 'EAF_LCA_results.xlsx';

writetable(LCA1, output_filename, 'Sheet', 'diesel+option1'); % Sheet1
writetable(LCA2, output_filename, 'Sheet', 'diesel+option2'); % Sheet2
writetable(LCA3, output_filename, 'Sheet', 'EV+option1');     % Sheet3
writetable(LCA4, output_filename, 'Sheet', 'EV+option2');     % Sheet4



