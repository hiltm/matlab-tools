%% --- CONFIGURATION ---
cal_dir = 'C:\GradSchool\Fall2025\Research\Chip Tamper\nanoVNA_cal\calibrations';  % path to .cal files

all_files = dir(fullfile(cal_dir, '*.cal'));
if isempty(all_files)
    error('No calibration files found in %s', cal_dir);
end

%% --- INITIALIZE ---
freq_ref = [];
cal_labels = {};
through_matrix = [];
short_matrix  = [];
open_matrix   = [];
load_matrix   = [];

%% --- READ EACH CALIBRATION FILE ---
for i = 1:length(all_files)
    cal_file = fullfile(cal_dir, all_files(i).name);
    fprintf('Reading %s\n', cal_file);

    fid = fopen(cal_file, 'r');
    cal_raw = textscan(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f', ...
        'CommentStyle', '#', 'HeaderLines', 0);
    fclose(fid);

    freq = cal_raw{1};
    if length(freq) < 2
        warning('Skipping file %s because frequency vector too short', all_files(i).name);
        continue;
    end

    ShortR = cal_raw{2}; ShortI = cal_raw{3};
    OpenR  = cal_raw{4}; OpenI  = cal_raw{5};
    LoadR  = cal_raw{6}; LoadI  = cal_raw{7};
    ThroughR = cal_raw{8}; ThroughI = cal_raw{9};
    ThrureflR = cal_raw{10}; ThrureflI = cal_raw{11};

    % Complex forms
    short_cmplx = ShortR + 1j*ShortI;
    open_cmplx  = OpenR  + 1j*OpenI;
    load_cmplx  = LoadR  + 1j*LoadI;
    through_cmplx = ThroughR + 1j*ThroughI;

    % Magnitudes in dB
    short_mag  = 20*log10(abs(short_cmplx));
    open_mag   = 20*log10(abs(open_cmplx));
    load_mag   = 20*log10(abs(load_cmplx));
    through_mag = 20*log10(abs(through_cmplx));

    % Normalize frequency grid if needed
    if isempty(freq_ref)
        freq_ref = freq;
    else
        short_mag   = interp1(freq, short_mag, freq_ref, 'linear', 'extrap');
        open_mag    = interp1(freq, open_mag, freq_ref, 'linear', 'extrap');
        load_mag    = interp1(freq, load_mag, freq_ref, 'linear', 'extrap');
        through_mag = interp1(freq, through_mag, freq_ref, 'linear', 'extrap');
    end

    % Store
    cal_labels{end+1} = erase(all_files(i).name, '.cal');
    cal_labels = arrayfun(@(x) sprintf('C%d', x), 1:length(cal_labels), 'UniformOutput', false);
    short_matrix  = [short_matrix,  short_mag];
    open_matrix   = [open_matrix,   open_mag];
    load_matrix   = [load_matrix,   load_mag];
    through_matrix = [through_matrix, through_mag];
end

%% --- PLOT ---
figure('Position',[100 100 1200 900]);
clim_short = [-80 5];  % Adjust these as you see fit
clim_open  = [-80 5];
clim_load  = [-80 5];
clim_through = [-60 10];
grid on;

subplot(2,2,1);
imagesc(1:length(cal_labels), freq_ref/1e9, short_matrix);
set(gca, 'YDir', 'normal', 'FontSize', 10);
colormap turbo; colorbar;
caxis(clim_short);
xlabel('Calibration File');
ylabel('Frequency (GHz)');
title('|Short| Magnitude (dB)');
xticks(1:length(cal_labels));
xticklabels(cal_labels);
xtickangle(45);
grid on;

subplot(2,2,2);
imagesc(1:length(cal_labels), freq_ref/1e9, open_matrix);
set(gca, 'YDir', 'normal', 'FontSize', 10);
colormap turbo; colorbar;
caxis(clim_open);
xlabel('Calibration File');
ylabel('Frequency (GHz)');
title('|Open| Magnitude (dB)');
xticks(1:length(cal_labels));
xticklabels(cal_labels);
xtickangle(45);
grid on;

subplot(2,2,3);
imagesc(1:length(cal_labels), freq_ref/1e9, load_matrix);
set(gca, 'YDir', 'normal', 'FontSize', 10);
colormap turbo; colorbar;
caxis(clim_load);
xlabel('Calibration File');
ylabel('Frequency (GHz)');
title('|Load| Magnitude (dB)');
xticks(1:length(cal_labels));
xticklabels(cal_labels);
xtickangle(45);
grid on;

subplot(2,2,4);
imagesc(1:length(cal_labels), freq_ref/1e9, through_matrix);
set(gca, 'YDir', 'normal', 'FontSize', 10);
colormap turbo; colorbar;
caxis(clim_through);
xlabel('Calibration File');
ylabel('Frequency (GHz)');
title('|Through| Magnitude (dB)');
xticks(1:length(cal_labels));
xticklabels(cal_labels);
xtickangle(45);
grid on;

sgtitle('NanoVNA Calibration Data Comparison — All Standards (dB Magnitude)', 'FontSize', 16, 'FontWeight', 'bold');
