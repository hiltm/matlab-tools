% Compare 8 spreadsheets over time and find differences
C1 = 'csv/Calibration_1759290096.3575184.csv';
%C2 = 'csv/Calibration_1759291224.1132913.csv';
C3 = 'csv/Calibration_1759292008.3265417.csv';
C4 = 'csv/Calibration_1759292894.8773572.csv';
C5 = 'csv/Calibration_1759293822.2345636.csv';
C6 = 'csv/Calibration_1759294702.0833251.csv';
C7 = 'csv/Calibration_1759295000.2331088.csv';
C8 = 'csv/Calibration_1759295611.2644002.csv';

% Specify the file names (adjust paths as needed)
fileNames = {
%    'file1.xlsx', 'file2.xlsx', 'file3.xlsx', 'file4.xlsx', 
%    'file5.xlsx', 'file6.xlsx', 'file7.xlsx', 'file8.xlsx'
%     C1, C2, C3, C4, C5, C6, C7, C8
     C1, C3, C4, C5, C6, C7, C8
};

num_files = length(fileNames);

% Pre-allocate cell array to hold the data from each file
data = cell(1, num_files);

% Load data from each file
for i = 1:num_files
    % Read the spreadsheet into a table (assumes data starts from row 2)
    data{i} = readtable(fileNames{i}, 'Range', 'A2:L1000'); % Adjust range as needed
end

% Assuming the column names are the same across all files, and they are consistent
%columnNames = data{1}.Properties.VariableNames;
columnNames = {};  % Initialize an empty cell array to store column names

%for i = 1:num_files
    % Read the table only once and store the column names
    tableData = readtable(fileNames{1});  % Read table for the i-th file
    for j = 1:length(tableData.Properties.VariableNames)
        columnNames{end+1} = tableData.Properties.VariableNames{j};  % Append column names
    end
%end

% Initialize a matrix to store differences for each column
% Number of rows is equal to the number of data points, and columns are the data columns
numRows = height(data{1});
numCols = numel(columnNames)-2; % TODO don't know why I had to subtract 2 but it was breaking difference below without it
differences = zeros(numRows, numCols, 7); % We compare between 8 files, so 7 comparisons

% Loop through each row and column to calculate differences between consecutive files
for r = 1:numRows
    for c = 1:numCols
        for i = 2:num_files
            disp(numCols)
            % Calculate the difference between the current file and the previous one
            differences(r, c, i-1) = data{i}{r, c} - data{i-1}{r, c};
        end
    end
end

% Display the differences for each column
for c = 1:numCols
    fprintf('Column: %s\n', columnNames{c});
    
    % Display the differences between each pair of consecutive files
    for i = 1:7
        fprintf('Difference between file %d and file %d:\n', i, i+1);
        disp(differences(:,:,i));
    end
end

% Optionally, plot differences for each column over time
% For each column, you can plot the differences over the rows (time)
%figure;
%for c = 1:numCols
%    subplot(numCols, 1, c);
%    hold on;
%    for i = 1:7
%        plot(1:numRows, squeeze(differences(:, c, i)), 'DisplayName', sprintf('File %d - File %d', i, i+1));
%    end
%    title(['Differences for column: ', columnNames{c}]);
%    xlabel('Time (Row number)');
%    ylabel('Difference');
%    legend;
%end

% % Loop over the columns (variables) and create separate figures
% for c = 1:numCols
%     figure; % Create a new figure for each column
% 
%     hold on;
%     for i = 1:7
%         plot(1:numRows, squeeze(differences(:, c, i)), 'DisplayName', sprintf('File %d - File %d', i, i+1));
%     end
% 
%     % Title and labels
%     title(['Differences for column: ', columnNames{c}]);
%     xlabel('Frequency Points');
%     ylabel('Difference');
%     legend;
% end

% Assuming you have 'differences' (3D matrix), 'columnNames' (cell array with column names), and 'numRows' (number of rows)

% Set number of rows and columns for the subplots (if using subplots)
rows = 4; % Adjust as needed
cols = 3; % Adjust as needed

% Create a new figure for each column
for c = 1:numCols
    figure; % New figure for each column

    hold on;
    % Loop through each file pair (File 1 - File 2, File 2 - File 3, ..., File 7 - File 8)
    for i = 1:7
        plot(1:numRows, squeeze(differences(:, c, i)), 'DisplayName', sprintf('C%d', i)); % Use C1, C2, ...
    end

    % Set title, x-label, and y-label
    title(['Differences for column: ', columnNames{c}]); % Display actual column name
    xlabel('Time (Row number)');
    ylabel('Difference');

    % Add legend
    legend;

    % Optional: Adjust the axis limits for better visualization
    xlim([0, numRows]);
    ylim([-2, 2]); % Adjust as per your data range
end
