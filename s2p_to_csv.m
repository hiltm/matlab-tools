% convert .s2p files to .csv while preserving the original file and removing headers
function s2p_to_csv(folder)
% get a list of all .s2p files in the folder
s2pFiles = dir(fullfile(folder, '*.s2p'));

% loop through each .s2p file
for i = 1:length(s2pFiles)
    % get the full path to the .s2p file
    s2pFile = fullfile(folder, s2pFiles(i).name);
    
    % open the .s2p file for reading
    fid = fopen(s2pFile, 'r');
    
    % initialize a cell array to store the data
    data = [];
    
    % read the file line by line
    tline = fgetl(fid);
    while ischar(tline)
        % skip header lines which start with '#' or '!'
        if (~startsWith(tline, '#') && ~startsWith(tline, '!')) && ~isempty(strtrim(tline))
            % split the line into columns by whitespace
            row = str2double(strsplit(strtrim(tline)));
            
            if numel(row) == 9
                % add the row of data to the matrix
                data = [data; row];
            end
        end
        tline = fgetl(fid);
    end
    
    % close the .s2p file
    fclose(fid);
    
    % create the output file path for the .csv
    [~, name, ~] = fileparts(s2pFile);
    csvFile = fullfile(folder, [name, '.csv']);
    
    % write the data to the .csv file
    csvwrite(csvFile, data);
    
    disp(['Converted ', s2pFile, ' to ', csvFile]);
end
