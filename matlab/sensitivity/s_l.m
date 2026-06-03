filename = 'BOF_Indirect_dissolution_result.xlsx';
sheetName = 'Sheet2';

data = readcell(filename, 'Sheet', sheetName);
[numRows, numCols] = size(data);

figure;
hold on;
colors = lines(numCols/2);
legendEntries = {};

for col = 1:2:numCols-1
    x_raw = data(2:end, col);
    y_raw = data(2:end, col+1);
    
    validIdx = ~cellfun(@isempty, x_raw) & ~cellfun(@isempty, y_raw);
    
    n = sum(validIdx);
    x = zeros(n,1);
    y = zeros(n,1);
    idxs = find(validIdx);
    for i=1:n
        valx = x_raw{idxs(i)};
        valy = y_raw{idxs(i)};
        if isnumeric(valx)
            x(i) = valx;
        else
            x(i) = str2double(valx);
        end
        if isnumeric(valy)
            y(i) = valy;
        else
            y(i) = str2double(valy);
        end
    end

    plot(x, y, 'LineWidth', 1.5, 'Color', colors((col+1)/2, :));
    legendEntries{end+1} = data{1, col+1};
end

xlabel('X axis');
ylabel('Y axis');
title('Multiple XY curves from Excel Sheet2 (10 groups)');
legend(legendEntries, 'Location', 'best');
grid on;
hold off;
