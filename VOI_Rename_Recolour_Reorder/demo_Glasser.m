% filepath_spreadsheet_input
%   * file can be any format supported by readtable (xls, xlsx, csv, etc.)
%   * each row must be a VOI, the order of rows will be the new order of
%       VOIs, and you may remove VOIs by excluding them from the table
%   * must contain the following columns:
%       1. CurrentName: the name of the VOI in the input .voi
%       2. NewName: the name of the VOI to use in the output .voi (leave empty to keep the current name)
%       3. NewColour: the hexcode of the colour to use in the output .voi (leave empty to keep the curernt colour)
filepath_spreadsheet_input = 'D:\Synology\CulhamLab\Documents\Brain Atlases\Glasser\Glasser_Reorganization_v0.1.xlsx';

% filepath_voi_input
%   * filepath to .voi input file
%   * you may exclude the folder if the file is in the working directory
filepath_voi_input = 'D:\Synology\CulhamLab\Documents\Brain Atlases\Glasser\MNI_Glasser_HCP_v1.0.voi';

% filepath_voi_output
%   * filepath to write the .voi output to
%   * you may exclude the folder if the file is in the working directory
filepath_voi_output = 'D:\Synology\CulhamLab\Documents\Brain Atlases\Glasser\MNI_Glasser_HCP_v1.0_ReorderRename.voi';

% overwrite (OPTIONAL)
%   * set true to overwrite the output .voi file
%   * defaults to false if empty or not provided
overwrite = false;

% column_name_CurrentName (OPTIONAL)
%   * set the expected column name for the VOI's current name
%   * defaults to CurrentName if empty or not provided
column_name_CurrentName = 'CurrentNames';

% column_name_NewName (OPTIONAL)
%   * set the expected column name for the VOI's new name
%   * defaults to NewName if empty or not provided
%   * set to Skip to fully disable renaming
column_name_NewName = 'New Name';

% column_name_NewColour (OPTIONAL)
%   * set the expected column name for the VOI's new colour hexcode
%   * defaults to NewColour if empty or not provided
%   * set to Skip to fully disable recolouring
column_name_NewColour = 'Skip';

% call the function
VOI_Rename_Recolour_Reorder(filepath_spreadsheet_input, ...
                            filepath_voi_input, ...
                            filepath_voi_output, ...
                            overwrite, ...
                            column_name_CurrentName, ...
                            column_name_NewName, ...
                            column_name_NewColour)