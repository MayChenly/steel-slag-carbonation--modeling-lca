% 修复文件路径（关键）
file1 = 'C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\indirect_lca_country_result.xlsx';
file2 = 'C:\Users\Liyuan Chen\Desktop\indirect\results\LCApart\country_information.xlsx';  % 手动重写路径！

% 读取表格
T1 = readtable(file1); 
T2 = readtable(file2); 


% 获取国家名称列（默认第一列）
country_names_1 = string(T1{:,1});
country_names_2 = string(T2{:,1});

% 匹配国家名并建立索引
[~, idx_map] = ismember(country_names_1, country_names_2);

% 保留国家列
country_column = T1(:,1); % 国家列

% -------- Sheet1 -------- %
col_B = T1{:,2};                    % Excel1 第B列
factors1 = T2{idx_map, [2 3 8]};    % Excel2 第B C H列
sheet1_result = col_B .* factors1;
sheet1_table = [country_column, array2table(sheet1_result, 'VariableNames', {'BOF_MIN', 'BOF_MAX', 'BOF_AVERAGE'})];

% -------- Sheet2 -------- %
col_C = T1{:,3};                    % Excel1 第C列
factors2 = T2{idx_map, [4 5 9]};    % Excel2 第D E I列
sheet2_result = col_C .* factors2;
sheet2_table = [country_column, array2table(sheet2_result, 'VariableNames', {'EAF_MIN', 'EAF_MAX', 'EAF_AVERAGE'})];

% -------- Sheet3 -------- %
col_D = T1{:,4};                    % Excel1 第D列
factors3 = T2{idx_map, [6 7 10]};   % Excel2 第F G J列
sheet3_result = col_D .* factors3;
sheet3_table = [country_column, array2table(sheet3_result, 'VariableNames', {'BF_MIN', 'BF_MAX', 'BF_AVERAGE'})];

% 写入新的 Excel 文件
output_file = 'combined_output_with_country.xlsx';
writetable(sheet1_table, output_file, 'Sheet', 'BOF');
writetable(sheet2_table, output_file, 'Sheet', 'EAF');
writetable(sheet3_table, output_file, 'Sheet', 'BF');
