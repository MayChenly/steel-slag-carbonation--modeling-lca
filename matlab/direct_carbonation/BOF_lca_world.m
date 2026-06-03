clear all
% Load BOF data
filename = 'BOF_lca_data';
data = readtable(filename, 'VariableNamingRule', 'preserve');

% Load emission factors
country_file = 'country_information.xlsx';
country_data = readtable(country_file);

% Create containers for each LCA group
LCA1_all = [];
LCA2_all = [];
LCA3_all = [];
LCA4_all = [];

for i = 1:height(country_data)
    country = country_data.Var1{i};
    country_emission_factor = country_data.Var11(i);

    % ==== 固定参数 ====
    CO2_concentration = 1; % bar
    BOF_mass = data.('SS_total_mass_kg');
    universial_gas_constant_R = 8.31;
    CO2_molar_mass = 44;

    CO2_gas_product_DAC = 1;
    tare_weight = 0.4212;
    distance_one_way = (0:500:3000)';
    road_trailer_emission_factor = 0.112;
    electrcity_truk = 0.921;
    total_weight = (CO2_gas_product_DAC + 2 * tare_weight);

    fan_energy = data.('fan_energy_MJ');
    carbonation_duration = data.('carbonation_duration_hr');
    crush_energy = data.('crushing_energy_kWh');
    CO2_total_supplied = data.('CO2_total_supplied_kg');
    CO2_total_stored = data.('CO2_total_stored_kg');

    % ==== DAC variables ====
    conversion_ratio = 1000 / BOF_mass;

    % Diesel + DAC option 1
    o1_CO2_removed_from_air = 0.769231;
    o1_electrcity_for_1_bar_CO2 = 152.8836;
    naturegas_for_1_bar_CO2 = 1121.796;

    o1_E_DAC = o1_electrcity_for_1_bar_CO2 * country_emission_factor;
    E_liquefaction = 89 * country_emission_factor;
    E_vaporisation = 5.4 * country_emission_factor;
    E_transportation = total_weight * distance_one_way * 2 * road_trailer_emission_factor;

    o1_R_part1 = o1_E_DAC + E_liquefaction + E_vaporisation + E_transportation;
    input_ratio = CO2_total_supplied / 1000 * conversion_ratio;
    E_transportation_input_ratio = E_transportation * input_ratio;

    o1_E_part1 = o1_R_part1 * input_ratio;
    E_crushing_chamber = crush_energy * country_emission_factor;
    E_fan_chamber = fan_energy / 3.6 * country_emission_factor;
    E_escape_chamber = CO2_total_supplied - CO2_total_stored;
    o1_R_DAC_chamber = CO2_total_supplied * o1_CO2_removed_from_air;

    E_crushing = E_crushing_chamber * conversion_ratio;
    E_fan = E_fan_chamber * conversion_ratio;
    E_escape = E_escape_chamber * conversion_ratio;
    o1_R_DAC = o1_R_DAC_chamber * conversion_ratio;
    o1_R_total = o1_E_part1 + E_crushing + E_fan + E_escape - o1_R_DAC;
    CO2_stored_tonneBOF = CO2_total_stored * conversion_ratio;

    % Diesel + DAC option 2
    o2_CO2_removed_from_air = 1;
    o2_electrcity_for_1_bar_CO2 = 7220 / 3.6;
    o2_E_DAC = o2_electrcity_for_1_bar_CO2 * country_emission_factor;
    o2_R_part1 = o2_E_DAC + E_liquefaction + E_vaporisation + E_transportation;
    o2_E_part1 = o2_R_part1 * input_ratio;
    o2_R_DAC_chamber = CO2_total_supplied * o2_CO2_removed_from_air;
    o2_R_DAC = o2_R_DAC_chamber * conversion_ratio;
    o2_R_total = o2_E_part1 + E_crushing + E_fan + E_escape - o2_R_DAC;

    % EV + DAC option 1
    e_E_transportation = distance_one_way * 2 * electrcity_truk * country_emission_factor;
    e1_R_part1 = o1_E_DAC + E_liquefaction + E_vaporisation + e_E_transportation;
    e_E_transportation_input_ratio = e_E_transportation * input_ratio;
    e1_E_part1 = e1_R_part1 * input_ratio;
    e1_R_DAC_chamber = CO2_total_supplied * o1_CO2_removed_from_air;
    e1_R_DAC = e1_R_DAC_chamber * conversion_ratio;
    e1_R_total = e1_E_part1 + E_crushing + E_fan + E_escape - e1_R_DAC;

    % EV + DAC option 2
    e2_R_part1 = o2_E_DAC + E_liquefaction + E_vaporisation + e_E_transportation;
    e2_E_part1 = e2_R_part1 * input_ratio;
    e2_R_DAC_chamber = CO2_total_supplied * o2_CO2_removed_from_air;
    e2_R_DAC = e2_R_DAC_chamber * conversion_ratio;
    e2_R_total = e2_E_part1 + E_crushing + E_fan + E_escape - e2_R_DAC;

    % ==== Create tables for each option, with Country column ====
    n = length(distance_one_way);
    Country_col = repmat({country}, n, 1);
    
    % Diesel + DAC option 1
    LCA1 = table(Country_col, distance_one_way, E_transportation_input_ratio, o1_R_total, ...
        'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'o1_R_total (kg)'});
    LCA2 = table(Country_col, repmat(CO2_stored_tonneBOF,n,1), ...
        repmat(o1_E_DAC * input_ratio,n,1), repmat(E_liquefaction*input_ratio,n,1), repmat(E_vaporisation*input_ratio,n,1), ...
        repmat(E_crushing,n,1), repmat(E_fan,n,1), repmat(E_escape,n,1), repmat(-o1_R_DAC,n,1), ...
        'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                          'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
    LCA1_all = [LCA1_all; [LCA2, LCA1(:,2:end)]];
    
    % Diesel + DAC option 2
    LCA3 = table(Country_col, distance_one_way, E_transportation_input_ratio, o2_R_total, ...
        'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'o2_R_total (kg)'});
    LCA4 = table(Country_col, repmat(CO2_stored_tonneBOF,n,1), ...
        repmat(o2_E_DAC * input_ratio,n,1), repmat(E_liquefaction*input_ratio,n,1), repmat(E_vaporisation*input_ratio,n,1), ...
        repmat(E_crushing,n,1), repmat(E_fan,n,1), repmat(E_escape,n,1), repmat(-o2_R_DAC,n,1), ...
        'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                          'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
    LCA2_all = [LCA2_all; [LCA4, LCA3(:,2:end)]];
    
    % EV + DAC option 1
    LCA5 = table(Country_col, distance_one_way, e_E_transportation_input_ratio, e1_R_total, ...
        'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'e1_R_total (kg)'});
    LCA6 = table(Country_col, repmat(CO2_stored_tonneBOF,n,1), ...
        repmat(o1_E_DAC * input_ratio,n,1), repmat(E_liquefaction*input_ratio,n,1), repmat(E_vaporisation*input_ratio,n,1), ...
        repmat(E_crushing,n,1), repmat(E_fan,n,1), repmat(E_escape,n,1), repmat(-e1_R_DAC,n,1), ...
        'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                          'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
    LCA3_all = [LCA3_all; [LCA6, LCA5(:,2:end)]];
    
    % EV + DAC option 2
    LCA7 = table(Country_col, distance_one_way, e_E_transportation_input_ratio, e2_R_total, ...
        'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'e2_R_total (kg)'});
    LCA8 = table(Country_col, repmat(CO2_stored_tonneBOF,n,1), ...
        repmat(o2_E_DAC * input_ratio,n,1), repmat(E_liquefaction*input_ratio,n,1), repmat(E_vaporisation*input_ratio,n,1), ...
        repmat(E_crushing,n,1), repmat(E_fan,n,1), repmat(E_escape,n,1), repmat(-e2_R_DAC,n,1), ...
        'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                          'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
    LCA4_all = [LCA4_all; [LCA8, LCA7(:,2:end)]];

end

% ==== 写入 Excel ====
output_filename = 'BOF_LCA_all_countries.xlsx';
writetable(LCA1_all, output_filename, 'Sheet', 'diesel+option1');
writetable(LCA2_all, output_filename, 'Sheet', 'diesel+option2');
writetable(LCA3_all, output_filename, 'Sheet', 'EV+option1');
writetable(LCA4_all, output_filename, 'Sheet', 'EV+option2');
