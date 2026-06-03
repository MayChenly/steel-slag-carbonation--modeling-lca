clear all
% 文件名定义
ss_file = '50km_SS_LCA_all_countries_v2.xlsx';
info_file = 'country_information.xlsx';
output_file = '50km_Processed_LCA_Output_v2.xlsx';

% 读取country_information.xlsx的sheet1
info_data = readtable(info_file, 'Sheet', 1);
Country = info_data{:, 1};        % 国家列
BOF_min = info_data{:, 2};
BOF_max = info_data{:, 3};
EAF_min = info_data{:, 4};
EAF_max = info_data{:, 5};
BF_min = info_data{:, 6};
BF_max = info_data{:, 7};
BOF_avg = info_data{:, 8};
EAF_avg = info_data{:, 9};
BF_avg = info_data{:, 10};
EMISSION_factor = info_data{:, 11}; % 备用，若需要用到

num_countries = length(Country);

% 设定option名称
optionNames = {'option1', 'option2', 'option3', 'option4'}; % 4个选项

% 先预定义输出数据容器
BOF_results = cell(4,1);
EAF_results = cell(4,1);
BF_results = cell(4,1);

% 读取0km_SS_LCA_all_countries_v2.xlsx的12个sheet
for i = 1:12
    raw_data = readmatrix(ss_file, 'Sheet', i);
    if size(raw_data, 2) < 12
        warning("Sheet %d 不足12列，跳过", i);
        continue;
    end
    
    L_col = raw_data(:, 12);
    min_len = min(length(L_col), num_countries);
    L_col = L_col(1:min_len);
    
    if i <= 4
        % BOF 数据 sheet 1-4
        M_max = L_col .* BOF_max(1:min_len);
        M_min = L_col .* BOF_min(1:min_len);
        M_avg = L_col .* BOF_avg(1:min_len);
        
        BOF_results{i} = table(Country(1:min_len), L_col, M_max, M_min, M_avg, ...
            'VariableNames', {'Country', 'Original', 'Max', 'Min', 'Average'});
        
    elseif i <= 8
        % EAF 数据 sheet 5-8
        M_max = L_col .* EAF_max(1:min_len);
        M_min = L_col .* EAF_min(1:min_len);
        M_avg = L_col .* EAF_avg(1:min_len);
        
        EAF_results{i-4} = table(Country(1:min_len), L_col, M_max, M_min, M_avg, ...
            'VariableNames', {'Country', 'Original', 'Max', 'Min', 'Average'});
        
    else
        % BF 数据 sheet 9-12
        M_max = L_col .* BF_max(1:min_len);
        M_min = L_col .* BF_min(1:min_len);
        M_avg = L_col .* BF_avg(1:min_len);
        
        BF_results{i-8} = table(Country(1:min_len), L_col, M_max, M_min, M_avg, ...
            'VariableNames', {'Country', 'Original', 'Max', 'Min', 'Average'});
    end
end

% 写入Excel文件，sheet命名
for i = 1:4
    % BOF sheets
    writetable(BOF_results{i}, output_file, 'Sheet', sprintf('BOF_Sheet_%d', i));
    % EAF sheets
    writetable(EAF_results{i}, output_file, 'Sheet', sprintf('EAF_Sheet_%d', i));
    % BF sheets
    writetable(BF_results{i}, output_file, 'Sheet', sprintf('BF_Sheet_%d', i));
end

% 合并summary，列顺序：
% Country | BOF_Max_1..4 | EAF_Max_1..4 | BF_Max_1..4 |
%         | BOF_Min_1..4 | EAF_Min_1..4 | BF_Min_1..4 |
%         | BOF_Avg_1..4 | EAF_Avg_1..4 | BF_Avg_1..4 |

max_mat = zeros(num_countries, 12);
min_mat = zeros(num_countries, 12);
avg_mat = zeros(num_countries, 12);

for i = 1:4
    try
        bof_tab = BOF_results{i};
        eaf_tab = EAF_results{i};
        bf_tab = BF_results{i};
        
        len = height(bof_tab);
        
        max_mat(1:len, i) = bof_tab.Max;
        max_mat(1:len, i+4) = eaf_tab.Max;
        max_mat(1:len, i+8) = bf_tab.Max;
        
        min_mat(1:len, i) = bof_tab.Min;
        min_mat(1:len, i+4) = eaf_tab.Min;
        min_mat(1:len, i+8) = bf_tab.Min;
        
        avg_mat(1:len, i) = bof_tab.Average;
        avg_mat(1:len, i+4) = eaf_tab.Average;
        avg_mat(1:len, i+8) = bf_tab.Average;
    catch
        warning('第%d组数据读取失败，跳过', i);
    end
end

max_names = [strcat('BOF_Max_', optionNames), strcat('EAF_Max_', optionNames), strcat('BF_Max_', optionNames)];
min_names = [strcat('BOF_Min_', optionNames), strcat('EAF_Min_', optionNames), strcat('BF_Min_', optionNames)];
avg_names = [strcat('BOF_Avg_', optionNames), strcat('EAF_Avg_', optionNames), strcat('BF_Avg_', optionNames)];

summary_table = table(Country, ...
    max_mat(:,1), max_mat(:,2), max_mat(:,3), max_mat(:,4), ...
    max_mat(:,5), max_mat(:,6), max_mat(:,7), max_mat(:,8), ...
    max_mat(:,9), max_mat(:,10), max_mat(:,11), max_mat(:,12), ...
    min_mat(:,1), min_mat(:,2), min_mat(:,3), min_mat(:,4), ...
    min_mat(:,5), min_mat(:,6), min_mat(:,7), min_mat(:,8), ...
    min_mat(:,9), min_mat(:,10), min_mat(:,11), min_mat(:,12), ...
    avg_mat(:,1), avg_mat(:,2), avg_mat(:,3), avg_mat(:,4), ...
    avg_mat(:,5), avg_mat(:,6), avg_mat(:,7), avg_mat(:,8), ...
    avg_mat(:,9), avg_mat(:,10), avg_mat(:,11), avg_mat(:,12), ...
    'VariableNames', [{'Country'}, max_names, min_names, avg_names]);

writetable(summary_table, output_file, 'Sheet', 'Summary');
