function data_preproc = Preprocessing_pipeline_interactive(cfg,pipeline_results)

% Performs the final steps of data analysis that requires user interaction.
% FT_DATABROWSER is used to visualise the independent components identified
% by ICA in PREPROCESSING_PIPELINE_NO_INTERACTIVE, and user input is
% required to identify and remove noisy components. The data is further
% processed to only include gradiometer channels, and be downsampled to 250
% Hz.
% 
% use as:
%   data_preproc = Preprocessing_pipeline_interactive(cfg, piepline_results, sub)
% 
% Input arguments:
% cfg
%   .faulty_trials      = a double array of faulty trial numbers. Can be
%                         empty if no trials are to be removed.
%   .faulty_channels    = a cell array containing the names of faulty
%                         channels, preceded by '-' (e.g. {'-MEG0123'}).
% 
% pipeline_results      = a 1x3 or 1x2 cell array of structs. the columns
%                         should contain the data spearated in blocks in
%                         column 1, the results of ICA in column 2, and
%                         optionally the full data_combined set in column
%                         3. Each struct is the result of the function
%                         PREPROCESSING_PIPELINE_NO_INTERACTIVE.
% 
% Output:
% data_preproc          = the fully preprocessed data for the input
%                         participant, separated based on sound category.

%% Check inputs
arguments
    cfg struct
    pipeline_results cell
end

% Check whether the pipeline_results input is valid, and is either a 1x2 or
% 1x3 cell of structs with at least 1 valid preprocessed data struct.

data_combi_fault = false;
if numel(pipeline_results) == 3 && isstruct(pipeline_results{3})
    if isfield(pipeline_results{3},'label') && any(contains(pipeline_results{3}.label,'EOG001'))
        data_combined = pipeline_results{3};
    else
        warning("The input pipeline_results contains 3 variables, but the third " + ...
            "variable cannot be identified as a preprocessed data struct. " + ...
            "Continuing with the first variable")
        data_combi_fault = true;
    end
end

if (numel(pipeline_results) == 2 && isstruct(pipeline_results{1})) || data_combi_fault
    field_names = fieldnames(pipeline_results{1});
    if all(contains(field_names,'block'))
        data_sep_in_blocks = struct2cell(pipeline_results{1});
        tmpcfg = [];
        tmpcfg.keepsampleinfo = 'no';

        % In the current dataset all participants have either done 9 or 10
        % blocks. The distinction needs to be made, as the data_combined
        % input for ICA in Preprocessing_pipeline_no_interactive is not
        % sequential because of how the dir function reads file names.
        if numel(data_sep_in_blocks) == 9
            data_combined = ft_appenddata(tmpcfg,data_sep_in_blocks{:});
            clear data_sep_in_blocks
        elseif numel(data_sep_in_blocks) == 10
            data_combined = ft_appenddata(tmpcfg,data_sep_in_blocks{1},...
                data_sep_in_blocks{10},data_sep_in_blocks{2:9});
            clear data_sep_in_blocks
        else
            error("The input pipeline_results contains an erroneous amount " + ...
                "of blocks for the struct in the first column. Number " + ...
                "should be either 9 or 10, but is %d",numel(data_sep_in_blocks))
        end
    else
        error("The input pipeline_results contains 2 variables, but the " + ...
            "first variable cannot be identified as a preprocessed data " + ...
            "struct separated into blocks")
    end
end

% If neither the first nor the third cells of the input pipeline_results
% are valid, the variable data_combined will be missing, and an error will
% be thrown.
if ~exist("data_combined","var")
    error("The input pipeline_results is not recognized as a valid input. " + ...
        "The variable should be a 1x2 or 1x3 cell of structs with at least " + ...
        "1 valid preprocessed data struct")
end

% Check whether the second cell of the input pipeline_results is a valid
% ICA result struct
if isstruct(pipeline_results{2})
    % Check if the second cell of the input pipeline_results contains a
    % fieldname associated with an ICA data struct
    if isfield(pipeline_results{2},'unmixing')
        data_comp = pipeline_results{2};
    else
        error("The input pipeline_results contains a valid data struct, " + ...
            "but the second variable cannot be identified as an ICA data " + ...
            "struct.")
    end
else
    error("The input pipeline_results is not recognized as a valid input. " + ...
        "The variable should be a 1x2 or 1x3 cell of structs with 1 valid " + ...
        "ICA data struct")
end

%% Observe components in data browser

% Visualize in ft_databrowser
tmpcfg = [];
tmpcfg.viewmode  = 'component';
tmpcfg.layout    = 'neuromag306all.lay';
ft_databrowser(tmpcfg, data_comp);

% Remove components that user marks with an array (can be [])
check_components_msg = "Please select components to reject: ";
check_components = input(check_components_msg);
tmpcfg = [];
tmpcfg.component = check_components;
data_clean = ft_rejectcomponent(tmpcfg,data_comp,...
    data_combined);
clear data_comp data_combined


%% Finalize the clean dataset
tmpcfg = [];
tmpcfg.channel = ['MEG*2','MEG*3',cfg.faulty_channels];
data_clean = ft_selectdata(tmpcfg,data_clean);

% downsample from 1000 Hz to 250 Hz for speed
tmpcfg = [];
tmpcfg.resamplefs = 250; % resample to 250 Hz
tmpcfg.detrend = 'no'; % default. Don't want to risk removing relevant trends
tmpcfg.method = 'downsample';
data = ft_resampledata(tmpcfg,data_clean);
clear data_clean

% separate the categories
tmpcfg = [];
dataset_names = {'data_objects','data_instruments','data_tools',...
    'data_animals','data_emotional','data_neutral'};
trial_types = unique(data.trialinfo(:,1));
for jj = 1:numel(trial_types)
    trial_type = trial_types(jj);
    tmpcfg.trials = data.trialinfo(:,1) == trial_type;
    data_preproc.(dataset_names{trial_type}) = ft_selectdata(tmpcfg,data);
end