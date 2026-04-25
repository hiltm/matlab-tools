% convert .s4p files to .csv while preserving data integrity and handling line wraps
function s4p_to_csv(folder)
    % get a list of all .s4p files in the folder
    s4pFiles = dir(fullfile(folder, '*.s4p'));
    
    for i = 1:length(s4pFiles)
        s4pFile = fullfile(folder, s4pFiles(i).name);
        fid = fopen(s4pFile, 'r');
        
        all_data = [];
        temp_row = [];
        
        tline = fgetl(fid);
        while ischar(tline)
            % clean the line and check if it's a comment or option line
            cleanLine = strtrim(tline);
            if isempty(cleanLine) || startsWith(cleanLine, '#') || startsWith(cleanLine, '!')
                tline = fgetl(fid);
                continue;
            end
            
            % convert line to numeric data
            rowValues = str2double(strsplit(cleanLine));
            temp_row = [temp_row, rowValues];
            
            % in s4p, a full data point consists of 1 Freq + 16 S-params (real/imag or mag/angle)
            % total of 33 values per frequency point
            if numel(temp_row) == 33
                all_data = [all_data; temp_row];
                temp_row = []; % reset for next frequency point
            end
            
            tline = fgetl(fid);
        end
        
        fclose(fid);
        
        % create output path
        [~, name, ~] = fileparts(s4pFile);
        csvFile = fullfile(folder, [name, '.csv']);
        
        % save as CSV
        if ~isempty(all_data)
            writematrix(all_data, csvFile);
            disp(['Converted ', s4pFiles(i).name, ' (', num2str(size(all_data, 1)), ' points)']);
        else
            warning(['No valid data found in ', s4pFiles(i).name]);
        end
    end
end