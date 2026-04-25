# matlab-tools

These MATLAB tools can be used for analyzing VNA data.
The scripts will have hard-coded paths if pointing to a certain folder; this is to perserve which data the script was used.
Most of the scripts require the RF-Toolbox MATLAB add-on.

## Tool Description
* s2p_tool - Define a folder path with multiple .s2p measurements. Cycle through measurements one at a time and get a real-time plot. There is an option to perserve a measurement on the plot window. Resulting plot is frequency versus magnitude of selected measurements.
* s2p_data_multiple_days - Define a parent directory with underlying directories named with the format YYYYMMDD. The output is a database containing many measurements. This database can then be used in tandem with other tools.
* s4p_to_csv : convert .s4p to .csv files
* generate_s2p_timelapse - Define a folder path with multiple .s2p measurements. These measurements will be plotted for frequency and magnitude, and a heatmap of variation from a nominal measurement. These will then be put all together into a singular .gif file and will loop.
* visualize_s2p : single file plots S11/S21 magnitude (dB), phase, and Smith chart. folder plots 3D waterfall of S11 magnitude over "time"