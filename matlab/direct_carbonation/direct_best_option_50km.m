clear;

input_file = '50km_SS_LCA_all_countries_v2.xlsx';
output_file = '50km_Min_Value_By_Option.xlsx';

% 获取所有 sheet 名称
[~, sheet_names] = xlsfinfo(input_file);

% 三个分组：BOF, EAF, BF
group_config = {
    1:4, 'BOF_Min';
    5:8, 'EAF_Min';
    9:12, 'BF_Min';
};

for g = 1:3
    sheet_idxs = group_config{g,1};
    output_sheet = group_config{g,2};
    
    num_options = length(sheet_idxs);
    data_block = [];
    option_labels = {};
    country_names = {};
    
    % 读取每个 sheet 的第12列和国家列（第1列）
    for i = 1:num_options
        sheet_name = sheet_names{sheet_idxs(i)};
        T = readtable(input_file, 'Sheet', sheet_name);
        
        if size(T, 2) < 12
            error('Sheet %s 少于12列', sheet_name);
        end
        
        if isempty(country_names)
            country_names = T{:,1};  % 国家列表
            num_countries = length(country_names);
            data_block = NaN(num_countries, num_options);
        end
        
        data_block(:, i) = T{:,12};  % 第12列数据
        option_labels{i} = sheet_name;
    end
    
    % 找最小值和对应option
    [min_vals, min_idx] = min(data_block, [], 2);
    min_options = option_labels(min_idx)';
    
     % 构造标志列：正数写 'False'，否则空字符串
    flag_column = strings(num_countries, 1);
    flag_column(min_vals > 0) = "False";  % 注意是字符串 "False"

    % 构建输出表
    result_table = table(country_names, min_vals, min_options, flag_column, ...
        'VariableNames', {'Country', 'MinValue', 'OptionLabel', 'Flag'});
    
    % 写入 Excel
    writetable(result_table, output_file, 'Sheet', output_sheet);
end
