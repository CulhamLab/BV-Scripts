% filepath_voi_input
%   * filepath to .voi input file
%   * you may exclude the folder if the file is in the working directory
filepath_voi_input = 'D:\Synology\CulhamLab\Documents\Brain Atlases\BV Julich-Brain Cytoarchitectonic Atlas\VOI\v29_ICBM152_LH_reorder.voi';

% filepath_spreadsheet_output
%   * filepath to the spreadsheet to write
%   * may be any filetype supported by writetable (xls, xlsx, csv, etc.)
filepath_spreadsheet_output = 'D:\Synology\CulhamLab\Documents\Brain Atlases\BV Julich-Brain Cytoarchitectonic Atlas\VOI\v29_ICBM152_LH_reorder.csv';

% overwrite (OPTIONAL)
%   * set true to overwrite the output spreadsheet file
%   * defaults to false if empty or not provided
overwrite = false;

% call the function
VOI_GetNames(filepath_voi_input, filepath_spreadsheet_output, overwrite)
