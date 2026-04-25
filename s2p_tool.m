classdef s2p_tool < handle
    % S2P_TOOL GUI to load, preview, and accumulate S-parameter data
    
    properties
        Fig             % UI figure
        Ax              % main axes
        ListBoxFiles    % list of loaded files
        DropDownParams  % S11, S21, S12, S22 selector
        CheckBoxSwap    % checkbox to flip S12/S21 logic
        LoadedData      % struct to store loaded S-parameter objects
        
        PreviewLine     % handle to the current DASHED line
        PlotCounter     % counter to manage colors for permanent lines
        StatusLabel     % label to show file count
    end
    
    methods
        function app = s2p_tool
            % Constructor: Initialize
            app.LoadedData = struct(); 
            app.PlotCounter = 0;
            app.buildUI();
        end
        
        function buildUI(app)
            % create the main window
            app.Fig = uifigure('Name', 'S2P Data Selector', ...
                'Position', [50 50 1400 650]);
            
            % layout grid: fixed control panel (280px), flexible plot area
            % renamed variable 'grid' to 'mainLayout' to avoid shadowing function
            mainLayout = uigridlayout(app.Fig, [1, 2]);
            mainLayout.ColumnWidth = {280, '1x'}; 
            
            % --- left panel (controls) ---
            panel = uipanel(mainLayout);
            panel.Title = 'Controls';
            
            vbox = uigridlayout(panel, [12, 1]); % Increased row count by 1
            vbox.RowHeight = {40, 20, '1x', 30, 20, 40, 30, 40, 40, 40, 40, 40};
            
            % 1. load directory
            uibutton(vbox, 'Text', '1. Load Directory', ...
                'ButtonPushedFcn', @app.onLoadDir);
            
            % status label
            app.StatusLabel = uilabel(vbox, 'Text', 'No files loaded', ...
                'HorizontalAlignment', 'center', 'FontColor', [0.4 0.4 0.4]);
            
            % 2. file list (browser)
            app.ListBoxFiles = uilistbox(vbox, ...
                'ValueChangedFcn', @app.updatePreview);
            
            % 3. navigation buttons
            navGrid = uigridlayout(vbox, [1, 2]);
            navGrid.Padding = [0 0 0 0];
            
            uibutton(navGrid, 'Text', '< Prev', ...
                'ButtonPushedFcn', @app.onPrev);
            uibutton(navGrid, 'Text', 'Next >', ...
                'ButtonPushedFcn', @app.onNext);
            
            uilabel(vbox, 'Text', 'Select Parameter:');
            
            % 4. parameter selector
            app.DropDownParams = uidropdown(vbox, ...
                'Items', {'S11', 'S21', 'S12', 'S22'}, ...
                'Value', 'S21', ...
                'ValueChangedFcn', @app.updatePreview);
                
            % swap checkbox
            % this is due to data logging issue with S12/S21 measurements being flipped
            app.CheckBoxSwap = uicheckbox(vbox, ...
                'Text', 'Swap S21/S12 (Fix Cabling)', ...
                'ValueChangedFcn', @app.updatePreview);
            
            % 5. add/keep button
            uibutton(vbox, 'Text', '2. Keep Data (Persist)', ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [0.30, 0.75, 0.93], ...
                'ButtonPushedFcn', @app.onConvertPreview);
            
            % 6. delete last trace
            uibutton(vbox, 'Text', 'Delete Last Trace', ...
                 'ButtonPushedFcn', @app.onDeleteLast);
            
            % 7. clear button
            uibutton(vbox, 'Text', 'Clear All Plots', ...
                'ButtonPushedFcn', @app.onClear);
            
            % 8. save button
            uibutton(vbox, 'Text', '3. Save Figure', ...
                'BackgroundColor', [0.47, 0.67, 0.19], ...
                'ButtonPushedFcn', @app.onSave);
            
            % --- right panel (plot) ---
            app.Ax = uiaxes(mainLayout);
            title(app.Ax, 'S-Parameter Comparison');
            xlabel(app.Ax, 'Frequency (GHz)');
            ylabel(app.Ax, 'Magnitude (dB)');
            
            % styling for readability
            grid(app.Ax, 'on');
            app.Ax.GridAlpha = 0.3;
            app.Ax.Box = 'on';
            
            % hold on must never be turned off
            hold(app.Ax, 'on'); 
        end
        
        %% core logic
        
        function [freq, mag_db, valid] = extractData(app)
            % data extraction helper
            freq = []; mag_db = []; valid = false;
            
            selFile = app.ListBoxFiles.Value;
            if isempty(selFile); return; end
            
            % ensure the selected file actually exists in loaded data
            if ~isfield(app.LoadedData, selFile)
                return;
            end
            
            dataStruct = app.LoadedData.(selFile);
            sobj = dataStruct.obj;
            
            freq = sobj.Frequencies / 1e9; 
            
            paramStr = app.DropDownParams.Value; 
            row = str2double(paramStr(2));
            col = str2double(paramStr(3));
            
            % --- logic insertion swap check for S12/S21 flip ---
            if app.CheckBoxSwap.Value
                % if we want S21 (row 2, col 1), grab S12 (row 1, col 2) instead
                if row == 2 && col == 1
                    row = 1; col = 2;
                % if we want S12 (row 1, col 2), grab S21 (row 2, col 1) instead
                elseif row == 1 && col == 2
                    row = 2; col = 1;
                end
                % note: S11 (1,1) and S22 (2,2) remain unaffected by a cable swap
            end
            % -----------------------------------
            
            s_data = rfparam(sobj, row, col);
            mag_db = 20 * log10(abs(s_data));
            valid = true;
        end
        
        function updatePreview(app, ~, ~)
            % 1. remove old preview line if it still exists
            if ~isempty(app.PreviewLine) && isvalid(app.PreviewLine)
                delete(app.PreviewLine);
            end
            
            % 2. extract data
            [freq, mag_db, isValid] = app.extractData();
            if ~isValid; return; end
            
            % 3. plot new preview (dashed, dark grey)
            app.PreviewLine = plot(app.Ax, freq, mag_db, ...
                'LineStyle', '--', ...
                'LineWidth', 2, ...
                'Color', [0.2 0.2 0.2]); 
            
            % 4. hide from legend
            app.PreviewLine.Annotation.LegendInformation.IconDisplayStyle = 'off';
            
            % 5. ensure preview is visible on top of other data
            uistack(app.PreviewLine, 'top');
        end
        
        function onConvertPreview(app, ~, ~)
            % convert the current preview line into a permanent line
            
            if isempty(app.PreviewLine) || ~isvalid(app.PreviewLine)
                return; % Nothing to add
            end
            
            % 1. get current file name for legend
            selFile = app.ListBoxFiles.Value;
            if ~isfield(app.LoadedData, selFile); return; end
            
            realName = app.LoadedData.(selFile).name;
            
            % 2. pick a color from the axes color order
            colors = colororder(app.Ax);
            colorIdx = mod(app.PlotCounter, size(colors, 1)) + 1;
            newColor = colors(colorIdx, :);
            
            % 3. modify the preview line properties to make it "permanent"
            app.PreviewLine.LineStyle = '-';        % Solid
            app.PreviewLine.LineWidth = 1.5;        % Standard width
            app.PreviewLine.Color = newColor;       % Assigned color
            
            % append ' (Swapped)' if the box is checked, for clarity
            displayName = realName;
            if app.CheckBoxSwap.Value
                displayName = [realName ' (Swapped)'];
            end
            app.PreviewLine.DisplayName = displayName; 
            
            % 4. Enable legend visibility
            app.PreviewLine.Annotation.LegendInformation.IconDisplayStyle = 'on';
            legend(app.Ax, 'show', 'Location', 'best', 'Interpreter', 'none');
            
            % 5. detach the handle
            app.PreviewLine = [];
            
            % 6. increment counter
            app.PlotCounter = app.PlotCounter + 1;
        end
        
        function changeSelection(app, direction)
            items = app.ListBoxFiles.Items;
            if isempty(items); return; end
            
            currentVal = app.ListBoxFiles.Value;
            idx = find(strcmp(items, currentVal), 1);
            if isempty(idx); idx = 1; end
            
            newIdx = idx + direction;
            if newIdx < 1; newIdx = 1; end
            if newIdx > length(items); newIdx = length(items); end
            
            app.ListBoxFiles.Value = items{newIdx};
            app.updatePreview();
        end
        
        %% callbacks
        
        function onLoadDir(app, ~, ~)
            folderPath = uigetdir(pwd, 'Select Folder');
            if isequal(folderPath, 0); return; end
            
            fileList = dir(fullfile(folderPath, '*.s2p'));
            if isempty(fileList)
                uialert(app.Fig, 'No .s2p files found.', 'No Files');
                return;
            end
            
            % 1. clean UI first to prevent callbacks firing on dead data
            app.ListBoxFiles.Items = {};
            app.ListBoxFiles.Value = {};
            
            % 2. reset data
            app.LoadedData = struct();
            app.PlotCounter = 0;
            app.onClear(); % Clears plot
            
            set(app.Fig, 'Pointer', 'watch'); drawnow;
            
            loadedCount = 0;
            for i = 1:length(fileList)
                fileName = fileList(i).name;
                fullPath = fullfile(fileList(i).folder, fileName);
                try
                    s_obj = sparameters(fullPath); 
                    safeName = matlab.lang.makeValidName(fileName);
                    app.LoadedData.(safeName) = struct('obj', s_obj, 'name', fileName);
                    loadedCount = loadedCount + 1;
                catch; end
            end
            
            set(app.Fig, 'Pointer', 'arrow');
            
            fieldList = fieldnames(app.LoadedData);
            app.ListBoxFiles.Items = fieldList;
            app.StatusLabel.Text = sprintf('%d Files Loaded', loadedCount);
            
            if ~isempty(fieldList)
                app.ListBoxFiles.Value = fieldList{1};
                app.updatePreview(); 
            end
        end
        
        function onPrev(app, ~, ~)
            app.changeSelection(-1);
        end
        
        function onNext(app, ~, ~)
            app.changeSelection(1);
        end
        
        function onDeleteLast(app, ~, ~)
            % deletes the most recently added premanent line
            allLines = findobj(app.Ax, 'Type', 'Line');
            if isempty(allLines); return; end
            
            % filter out the current preview line so we don't delete it
            savedLines = [];
            for i = 1:length(allLines)
                if allLines(i) ~= app.PreviewLine
                    savedLines = [savedLines; allLines(i)];
                end
            end
            
            % delete the newest permanent line
            if ~isempty(savedLines)
                delete(savedLines(1));
                app.PlotCounter = max(0, app.PlotCounter - 1);
            end
        end
        
        function onClear(app, ~, ~)
            cla(app.Ax);
            legend(app.Ax, 'off');
            app.PreviewLine = [];
            app.PlotCounter = 0;
            app.updatePreview(); 
        end
        
        function onSave(app, ~, ~)
            [file, path] = uiputfile({'*.png';'*.pdf';'*.fig'}, 'Save Figure');
            if isequal(file, 0); return; end
            
            [~, ~, ext] = fileparts(file);
            if strcmpi(ext, '.fig')
                savefig(app.Fig, fullfile(path, file));
            else
                exportgraphics(app.Ax, fullfile(path, file), 'Resolution', 300);
            end
        end
    end
end