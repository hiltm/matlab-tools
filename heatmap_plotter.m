% Directory containing the S2P files
data_dir = 'C:\GradSchool\Fall2025\Research\Chip Tamper\chiptamper_testdata\testdata3';

all_files = dir(fullfile(data_dir));
file_list = all_files(startsWith({all_files.name}, 'measurement'));

% Initialize variables
time = [];
data_matrix = [];
first_time = Inf;

% Loop over each file to read and process the S2P data
for i = 1:length(file_list)
    filename = file_list(i).name;
    time_str = extractBetween(filename, '_', '_');
    file_time = str2double(time_str{1});
    
    if file_time < first_time
        first_time = file_time;
    end

    file_path = fullfile(data_dir, filename);
    s_params = sparameters(file_path);
    freq = s_params.Frequencies;
    s11_mag = abs(squeeze(s_params.Parameters(1,1,:)));  % Flatten S11 to vector

    % Store data
    time = [time; file_time - first_time];
    data_matrix = [data_matrix, s11_mag];  % each column = one time point
end

% --- ROTATED HEATMAP (time = X-axis, frequency = Y-axis) ---
figure;
imagesc(time, freq, data_matrix);   % no transpose here!
set(gca, 'YDir', 'normal');         % low freq at bottom
xlabel('Time (s)');
ylabel('Frequency (Hz)');
colorbar;
title('Heatmap of S11 Magnitude over Time and Frequency (Rotated)');
colormap turbo;  % or 'jet', 'parula', etc.
