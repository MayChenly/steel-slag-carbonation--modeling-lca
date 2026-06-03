% ==== 固定参数 ====
distance_one_way = 0; % 固定距离
road_trailer_emission_factor = 0.112;
electrcity_truk = 0.921;
tare_weight = 0.4212;
total_weight = 1 + 2 * tare_weight;

% ==== 文件 & 国家数据 ====
country_file = 'country_information.xlsx';
country_data = readtable(country_file);

data_files = {'BOF_lca_data.xlsx', 'EAF_lca_data.xlsx', 'BF_lca_data.xlsx'};
output_filename = '0km_SS_LCA_all_countries_v2.xlsx';

sheet_names = {
    'BOF_diesel+option1', 'BOF_diesel+option2', 'BOF_EV+option1', 'BOF_EV+option2', ...
    'EAF_diesel+option1', 'EAF_diesel+option2', 'EAF_EV+option1', 'EAF_EV+option2', ...
    'BF_diesel+option1', 'BF_diesel+option2', 'BF_EV+option1', 'BF_EV+option2'
};


sheet_idx = 1;

for file_idx = 1:length(data_files)
    filename = data_files{file_idx};
    data = readtable(filename, 'VariableNamingRule', 'preserve');

    LCA1_all = [];
    LCA2_all = [];
    LCA3_all = [];
    LCA4_all = [];

    for i = 1:height(country_data)
        country = country_data.Var1{i};
        country_emission_factor = country_data.Var11(i);

        % ==== 参数 ====
        CO2_concentration = 1; % bar
        BOF_mass = data.('SS_total_mass_kg');
        conversion_ratio = 1000 ./ BOF_mass;
        universial_gas_constant_R = 8.31;
        CO2_molar_mass = 44;

        fan_energy = data.('fan_energy_MJ');
        carbonation_duration = data.('carbonation_duration_hr');
        crush_energy = data.('crushing_energy_kWh');
        CO2_total_supplied = data.('CO2_total_supplied_kg');
        CO2_total_stored = data.('CO2_total_stored_kg');

        % ==== DAC 基础 ====
        CO2_gas_product_DAC = 1;

        % Diesel + DAC option 1
        o1_CO2_removed_from_air = 0.769231;
        o1_electrcity_for_1_bar_CO2 = 152.8836;
        o1_E_DAC = o1_electrcity_for_1_bar_CO2 * country_emission_factor;
        E_liquefaction = 89 * country_emission_factor;
        E_vaporisation = 5.4 * country_emission_factor;
        E_transportation = total_weight * distance_one_way * 2 * road_trailer_emission_factor;
        input_ratio = CO2_total_supplied / 1000 .* conversion_ratio;
        E_transportation_input_ratio = E_transportation * input_ratio;

        o1_E_part1 = (o1_E_DAC + E_liquefaction + E_vaporisation + E_transportation) * input_ratio;
        E_crushing = crush_energy * country_emission_factor .* conversion_ratio;
        E_fan = fan_energy / 3.6 * country_emission_factor .* conversion_ratio;
        E_escape = (CO2_total_supplied - CO2_total_stored) .* conversion_ratio;
        o1_R_DAC = CO2_total_supplied * o1_CO2_removed_from_air .* conversion_ratio;
        o1_R_total = o1_E_part1 + E_crushing + E_fan + E_escape - o1_R_DAC;
        CO2_stored_tonneBOF = CO2_total_stored .* conversion_ratio;

        % Diesel + DAC option 2
        o2_CO2_removed_from_air = 1;
        o2_electrcity_for_1_bar_CO2 = 7220 / 3.6;
        o2_E_DAC = o2_electrcity_for_1_bar_CO2 * country_emission_factor;
        o2_E_part1 = (o2_E_DAC + E_liquefaction + E_vaporisation + E_transportation) * input_ratio;
        o2_R_DAC = CO2_total_supplied * o2_CO2_removed_from_air .* conversion_ratio;
        o2_R_total = o2_E_part1 + E_crushing + E_fan + E_escape - o2_R_DAC;

        % EV + DAC option 1
        e_E_transportation = distance_one_way * 2 * electrcity_truk * country_emission_factor;
        e1_E_part1 = (o1_E_DAC + E_liquefaction + E_vaporisation + e_E_transportation) * input_ratio;
        e1_R_DAC = CO2_total_supplied * o1_CO2_removed_from_air .* conversion_ratio;
        e1_R_total = e1_E_part1 + E_crushing + E_fan + E_escape - e1_R_DAC;

        % EV + DAC option 2
        e2_E_part1 = (o2_E_DAC + E_liquefaction + E_vaporisation + e_E_transportation) * input_ratio;
        e2_R_DAC = CO2_total_supplied * o2_CO2_removed_from_air .* conversion_ratio;
        e2_R_total = e2_E_part1 + E_crushing + E_fan + E_escape - e2_R_DAC;

        % ==== 结果表格 ====
        Country_col = repmat({country}, height(data), 1);
        Distance_col = repmat(distance_one_way, height(data), 1);

        % Diesel + DAC option 1
        T1 = table(Country_col, Distance_col, repmat(E_transportation_input_ratio, height(data), 1), o1_R_total, ...
            'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'o1_R_total (kg)'});
        T2 = table(Country_col, CO2_stored_tonneBOF, ...
            o1_E_DAC * input_ratio, E_liquefaction * input_ratio, E_vaporisation * input_ratio, ...
            E_crushing, E_fan, E_escape, -o1_R_DAC, ...
            'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                              'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
        LCA1_all = [LCA1_all; [T2, T1(:,2:end)]];

        % Diesel + DAC option 2
        T3 = table(Country_col, Distance_col, repmat(E_transportation_input_ratio, height(data), 1), o2_R_total, ...
            'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'o2_R_total (kg)'});
        T4 = table(Country_col, CO2_stored_tonneBOF, ...
            o2_E_DAC * input_ratio, E_liquefaction * input_ratio, E_vaporisation * input_ratio, ...
            E_crushing, E_fan, E_escape, -o2_R_DAC, ...
            'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                              'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
        LCA2_all = [LCA2_all; [T4, T3(:,2:end)]];

        % EV + DAC option 1
        T5 = table(Country_col, Distance_col, repmat(e_E_transportation * input_ratio, height(data), 1), e1_R_total, ...
            'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'e1_R_total (kg)'});
        T6 = table(Country_col, CO2_stored_tonneBOF, ...
            o1_E_DAC * input_ratio, E_liquefaction * input_ratio, E_vaporisation * input_ratio, ...
            E_crushing, E_fan, E_escape, -e1_R_DAC, ...
            'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                              'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
        LCA3_all = [LCA3_all; [T6, T5(:,2:end)]];

        % EV + DAC option 2
        T7 = table(Country_col, Distance_col, repmat(e_E_transportation * input_ratio, height(data), 1), e2_R_total, ...
            'VariableNames', {'Country','Distance (km)', 'transportation (kg)', 'e2_R_total (kg)'});
        T8 = table(Country_col, CO2_stored_tonneBOF, ...
            o2_E_DAC * input_ratio, E_liquefaction * input_ratio, E_vaporisation * input_ratio, ...
            E_crushing, E_fan, E_escape, -e2_R_DAC, ...
            'VariableNames', {'Country','CO2 stored (kg)','DAC process(kg)','liquefaction (kg)',...
                              'vaporisation (kg)','Crushing (kg)','Fan (kg)','CO2 escape (kg)','CO2 removal from air'});
        LCA4_all = [LCA4_all; [T8, T7(:,2:end)]];
    end

    % ==== 写入 Sheet ====
    writetable(LCA1_all, output_filename, 'Sheet', sheet_names{sheet_idx}); sheet_idx = sheet_idx + 1;
    writetable(LCA2_all, output_filename, 'Sheet', sheet_names{sheet_idx}); sheet_idx = sheet_idx + 1;
    writetable(LCA3_all, output_filename, 'Sheet', sheet_names{sheet_idx}); sheet_idx = sheet_idx + 1;
    writetable(LCA4_all, output_filename, 'Sheet', sheet_names{sheet_idx}); sheet_idx = sheet_idx + 1;
end
