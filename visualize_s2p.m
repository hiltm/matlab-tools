function visualize_s2p(targetPath)
% VISUALIZE_S2P loads and plots Touchstone (.s2p) data
%   targetPath: string path to a single .s2p file OR a folder of .s2p files
%
%   MODES:
%   1. single file: plots S11/S21 magnitude (dB), phase, and Smith chart
%   2. folder:      plots a 3D waterfall of S11 magnitude over "time" (file index)

    % check arguments
    if nargin < 1
        % default to picking a folder via UI if no argument provided
        targetPath = uigetdir(pwd, 'Select Folder with .s2p Files');
        if targetPath == 0; return; end
    end

    if isfile(targetPath)
        plot_single_file(targetPath);
    elseif isfolder(targetPath)
        plot_folder_waterfall(targetPath);
        visualize_batch_2d(targetPath);
    else
        error('Invalid path specified.');
    end
end

%% --- MODE 1: single file analyzer ---
function plot_single_file(filename)
    % load data
    try
        sobj = sparameters(filename);
    catch ME
        error(['Failed to load .s2p: ' ME.message]);
    end
    
    freq = sobj.Frequencies;
    s11 = squeeze(sobj.Parameters(1,1,:));
    s21 = squeeze(sobj.Parameters(2,1,:));
    
    % Create Figure
    figure('Name', ['Analysis: ' filename], 'Color', 'w', 'Position', [100 100 1200 800]);
    
    % 1. S11/S21 magnitude (dB)
    subplot(2,2,1);
    plot(freq/1e6, 20*log10(abs(s11)), 'b', 'LineWidth', 1.5); hold on;
    plot(freq/1e6, 20*log10(abs(s21)), 'r', 'LineWidth', 1.5);
    title('Magnitude Response');
    xlabel('Frequency (MHz)'); ylabel('Magnitude (dB)');
    legend('S11', 'S21'); grid on; xlim([min(freq) max(freq)]/1e6);
    
    % 2. S11/S21 phase (degrees)
    subplot(2,2,2);
    plot(freq/1e6, rad2deg(angle(s11)), 'b', 'LineWidth', 1); hold on;
    plot(freq/1e6, rad2deg(angle(s21)), 'r', 'LineWidth', 1);
    title('Phase Response');
    xlabel('Frequency (MHz)'); ylabel('Phase (Deg)');
    grid on; xlim([min(freq) max(freq)]/1e6);
    
    % 3. Smith chart (S11)
    subplot(2,2,[3 4]);
    
    if exist('smithplot', 'file')
        try
            h = smithplot(sobj, 1, 1, 'Title', 'S11 Smith Chart (Impedance)');
            
            % attempt to set legend if property exists, otherwise ignore
            try h.LegendLabels = {'S11 Measured'}; catch; end
            
        catch
            % fallback for very old versions or specific restricted handles
            h = smithplot(sobj, 1, 1);
            title('S11 Smith Chart (Impedance)'); 
        end
    else
        % fallback if RF Toolbox is missing smithplot entirely
        text(0.5, 0.5, 'Smith Chart unavailable', 'HorizontalAlignment', 'center');
    end
end

%% --- MODE 2: batch trend analyzer (waterfall) ---
function plot_folder_waterfall(folderPath)
    % find all .s2p files
    files = dir(fullfile(folderPath, '*.s2p'));
    
    if isempty(files)
        error('No .s2p files found in this folder.');
    end
    
    % sort files naturally (assuming timestamp in filename)
    % this ensures time progresses linearly in the plot
    [~, idx] = sort({files.name});
    files = files(idx);
    
    numFiles = length(files);
    fprintf('Found %d files. Loading data...\n', numFiles);
    
    % pre-allocate arrays for speed
    % read first file to get frequency points
    tempS = sparameters(fullfile(files(1).folder, files(1).name));
    freqs = tempS.Frequencies;
    numFreqs = length(freqs);
    
    % matrix: rows = time (file index), cols = frequency
    s11_matrix = zeros(numFiles, numFreqs);
    
    wb = waitbar(0, 'Loading Touchstone Files...');
    for i = 1:numFiles
        if mod(i, 10) == 0; waitbar(i/numFiles, wb); end
        
        try
            path = fullfile(files(i).folder, files(i).name);
            sobj = sparameters(path);
            s11_complex = squeeze(sobj.Parameters(1,1,:));
            s11_matrix(i, :) = 20*log10(abs(s11_complex));
        catch
            warning(['Skipping corrupt file: ' files(i).name]);
        end
    end
    close(wb);
    
    % --- visualization: waterfall ---
    figure('Name', 'Reflectometry Trend Analysis', 'Color', 'w', 'Position', [100 100 1000 700]);
    
    % use MESH or SURF for 3D
    % X = Frequency, Y = File Index (Time), Z = Magnitude
    [X, Y] = meshgrid(freqs/1e6, 1:numFiles);
    
    s = surf(X, Y, s11_matrix);
    
    s.EdgeColor = 'none'; % remove mesh lines for smoothness
    colormap(jet);        % 'jet' or 'parula' give good contrast for signal strength
    c = colorbar;
    c.Label.String = 'Magnitude (dB)';
    
    title(sprintf('S11 Waterfall: %d Measurements', numFiles));
    xlabel('Frequency (MHz)');
    ylabel('Measurement Index (Time)');
    zlabel('Magnitude (dB)');
    
    % set view angle (standard 3D view)
    view(-45, 30); 
    
    % lighting (optional, makes 3D features pop)
    camlight left; lighting gouraud;
    
    % optional: add a baseline subtraction subplot
    % just simple rotation is usually enough for analysis
    axis tight;
end

function visualize_batch_2d(folderPath)
    % VISUALIZE_BATCH_2D generates 2D plots from batch S2P data
    
    if nargin < 1
        folderPath = uigetdir(pwd, 'Select Data Folder');
        if folderPath == 0; return; end
    end

    % --- 1. load data ---
    files = dir(fullfile(folderPath, '*.s2p'));
    if isempty(files); error('No .s2p files found.'); end
    
    % sort by name (timestamp)
    [~, idx] = sort({files.name});
    files = files(idx);
    numFiles = length(files);
    
    tempS = sparameters(fullfile(files(1).folder, files(1).name));
    freqs = tempS.Frequencies/1e6; % Convert to MHz
    numFreqs = length(freqs);
    s11_db = zeros(numFiles, numFreqs);
    s21_db = zeros(numFiles, numFreqs);
    
    fprintf('Processing %d files...\n', numFiles);
    
    % fast load loop
    for i = 1:numFiles
        try
            sobj = sparameters(fullfile(files(i).folder, files(i).name));
            s11_db(i, :) = 20*log10(abs(squeeze(sobj.Parameters(1,1,:))));
            s21_db(i, :) = 20*log10(abs(squeeze(sobj.Parameters(2,1,:))));
        catch
            s11_db(i, :) = NaN; % Handle corrupt files gracefully
            s21_db(i, :) = NaN; % Handle corrupt files gracefully
        end
    end

    % --- plot 1A: heatmap spectrogram ---
    figure('Name', 'Heatmap Analysis', 'Color', 'w', 'Position', [100 100 800 500]);
    
    % imagesc is faster than surf for 2D views
    imagesc(freqs, 1:numFiles, s11_db);
    
    set(gca, 'YDir', 'normal'); % time grows upwards
    colormap(jet);
    c = colorbar;
    c.Label.String = 'Magnitude (dB)';
    c.Label.FontSize = 10;
    
    title('S11 Magnitude Heatmap');
    xlabel('Frequency (MHz)');
    ylabel('Measurement Index (Time)');

    % --- plot 1B: heatmap spectrogram ---
    figure('Name', 'Heatmap Analysis', 'Color', 'w', 'Position', [100 100 800 500]);
    
    % imagesc is faster than surf for 2D views
    imagesc(freqs, 1:numFiles, s21_db);
    
    set(gca, 'YDir', 'normal'); % time grows upwards
    colormap(jet);
    c = colorbar;
    c.Label.String = 'Magnitude (dB)';
    c.Label.FontSize = 10;
    
    title('S21 Magnitude Heatmap');
    xlabel('Frequency (MHz)');
    ylabel('Measurement Index (Time)');
    
    % --- Plot 2: statistical envelope (min/max/mean) ---
    figure('Name', 'Statistical Envelope', 'Color', 'w', 'Position', [150 150 800 500]);
    
    mean_trace = mean(s11_db, 1, 'omitnan');
    min_trace = min(s11_db, [], 1, 'omitnan');
    max_trace = max(s11_db, [], 1, 'omitnan');
    
    % create filled patch for the range
    x_fill = [freqs', fliplr(freqs')];
    y_fill = [max_trace, fliplr(min_trace)];
    
    fill(x_fill, y_fill, [0.8 0.8 1], 'EdgeColor', 'none', 'FaceAlpha', 0.5); 
    hold on;
    
    % plot the mean line on top
    plot(freqs, mean_trace, 'b', 'LineWidth', 1.5);
    
    grid on;
    title(sprintf('System Stability (N=%d samples)', numFiles));
    xlabel('Frequency (MHz)');
    ylabel('Magnitude (dB)');
    legend('Min-Max Range', 'Mean Response', 'Location', 'best');
    xlim([min(freqs) max(freqs)]);
    
    % --- plot 3: resonance drift over time ---
    % find the frequency index with the deepest null (resonance) in the first measurement
    [~, res_idx] = min(s11_db(1, :));
    target_freq = freqs(res_idx);
    
    figure('Name', 'Resonance Tracking', 'Color', 'w', 'Position', [200 200 800 400]);
    
    plot(1:numFiles, s11_db(:, res_idx), 'r-', 'LineWidth', 1.2);
    
    grid on;
    title(sprintf('Stability at Resonance (%.2f MHz)', target_freq));
    xlabel('Measurement Index');
    ylabel('Magnitude (dB)');
    
    % add basic stats to the plot
    y_std = std(s11_db(:, res_idx));
    text(5, max(s11_db(:, res_idx)), sprintf('\\sigma = %.3f dB', y_std), ...
        'BackgroundColor', 'w', 'EdgeColor', 'k');
end