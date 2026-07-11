function save_mvpa_statistics(names,MVPA_results)

% Saves input MVPA statistics results into their corresponding Results
% folder with unique names.
%
% use as:
%   save_mvpa_statistics(names,MVPA_results)
%
% Input arguments:
% names             = the unique naming convention for each run of MVPA per
%                     participant. Should be a 1xN cell of strings or chars
%                     , where N matches the number of elements in the cell 
%                     for each MVPA_results field
%
% MVPA_results      = Output of mvpa_pipeline_full_cfg. Struct with fields
%                     corresponding to participants. Each field contains an
%                     1xN cell, where N is the number of MVPA runs



%% Save data to Results directory
data_dir = fullfile('..','Data','Results');
for ii = 1:numel(fieldnames(MVPA_results))
   subjects = fieldnames(MVPA_results);
   sub = subjects{ii};
   savefile_dir = fullfile(data_dir,sub);
   for jj = 1:numel(names)
       save_name = strcat("stat_",sub,"_",names{jj});
       full_savefile_name = fullfile(savefile_dir,save_name);
       S = [];
       S.(save_name) = MVPA_results.(sub){jj};
       fprintf('Saving %s to directory %s \n',save_name,savefile_dir)
       save(full_savefile_name,'-struct','S',save_name)
   end
end
