function data_no_interactive = Preprocessing_pipeline_no_interactive(cfg,sub)

% Reads data from directories and performs a prepared preprocessing 
% pipeline on the input subjects, and removes channels and trials specified
% by the user.
% 
% use as:
%   data_no_interactive = Preprocessing_pipeline(cfg, subjects)
% 
% Input arguments:
% cfg
%   .faulty_trials      = a double array of faulty trial numbers. Can be
%                         empty if no trials are to be removed.
%   .faulty_channels    = a cell array containing the names of faulty
%                         channels, preceded by '-' (e.g. {'-MEG0123'}).
% 
% sub                   = a single string scalar or character vector with 
%                         the identifier of a subject.
% 
% Output:
% data_no_interactive   = A 2x1 cell of structs containing first the 
%                         combined processed data of all blocks for the 
%                         participant, and second the output of independent
%                         component analysis (ICA)

%% Check inputs
arguments
    cfg struct
    sub {mustBeText} = 'select'
end

if any(strcmp(sub,'select'))
    raw_data_dir        = fullfile('..','Data','Raw');
    sub_directory       = dir(raw_data_dir);
    sub_options         = {sub_directory.name};
    select_subject_msg  = "Select subject directories";

    [indx,tf] = listdlg('PromptString',select_subject_msg,'ListString',...
        sub_options,'SelectionMode','single');

    if ~tf || isempty(indx)
        error('No subjects have been selected');
    else
        sub = sub_options(indx);
    end
end

%% First get the subject info

% request the subject name
raw_data_dir    = fullfile('..','Data','Raw');

% gain access to the subject files
subj            = [];
subj.rawdir     = fullfile(raw_data_dir,sub);

csv_d           = dir(fullfile(subj.rawdir, '*.csv'));
subj.datatable  = fullfile(csv_d.folder, csv_d.name);

d               = dir(fullfile(subj.rawdir, '*.fif'));
data_blocks     = cell(length(d),1);

%% Band-pass filtering, defining trials and demeaning for all blocks
for ii = 1:length(d)
    fprintf('currently processing block %d of %d \n',ii,length(d));
    pause(1.2);
    subj.dataset = fullfile(d(ii).folder, d(ii).name);

    % create a bandpass filtered and baseline corrected dataset prior
    % to setting the trials
    tmpcfg = [];
    tmpcfg.dataset      = subj.dataset;
    tmpcfg.channel      = {'all'};
    tmpcfg.bpfilter     = 'yes';        % apply bandpass filter
    tmpcfg.bpfreq       = [0.5 40];     % bandpass filter between 0.5 Hz and 40 Hz
    tmpcfg.continuous   = 'yes';
    tmpcfg.bpfilttype   = 'firws';      % to avoid flowover into prestim
    tmpcfg.bpfiltdir    = 'onepass-reverse-zerophase';
    data_bp             = ft_preprocessing(tmpcfg);

    % set the trials
    tmpcfg              = [];
    tmpcfg.dataset      = subj.dataset;
    tmpcfg.datatable    = subj.datatable;
    tmpcfg.trialfun     = 'function_sound_delay'; % or another if necessary
    tmp                 = ft_definetrial(tmpcfg);

    % create a dataset with defined trials from the previously created 
    % bandpass filtered and baseline corrected dataset
    tmpcfg                  = [];
    tmpcfg.trl              = tmp.trl;
    data_trialset_bp        = ft_redefinetrial(tmpcfg,data_bp);
    clear data_bp

    % demean the trialed data using the entire trial
    tmpcfg              = [];
    tmpcfg.demean       = 'yes';
    data_blocks{ii,1}   = ft_preprocessing(tmpcfg,data_trialset_bp);
    clear data_trialset_bp
end
% combine the data of all blocks
tmpcfg = [];
tmpcfg.keepsampleinfo = 'no'; % sample info cannot be kept because each block starts over
data_combined = ft_appenddata(tmpcfg,data_blocks{1:end,1});
clear data_blocks

%% Remove faulty trials
faulty_trials = cfg.faulty_trials;

if ~isempty(faulty_trials)
    tmpcfg = [];
    tmpcfg.trials = 1:numel(data_combined.trial);
    tmpcfg.trials(faulty_trials) = [];
    data_combined = ft_selectdata(tmpcfg,data_combined);
end

%% Run ICA

tmpcfg = [];
tmpcfg.method           = 'runica';
tmpcfg.demean           = 'no';     % it has already been baseline corrected
tmpcfg.numcomponent    = 'all';
tmpcfg.channel = ['MEG',cfg.faulty_channels];
data_comp = ft_componentanalysis(tmpcfg,data_combined);

%% Finalize output

% separate the data into a struct with separate fields for each block. This
% makes it easier to save the result in a .mat file.
tmpcfg = [];
block_nums = unique(data_combined.trialinfo(:,2));
for jj = 1:numel(block_nums)
    block_num = block_nums(jj);
    dataset_name = "block_" + num2str(block_num);
    tmpcfg.trials = data_combined.trialinfo(:,2) == block_num;
    sep_in_blocks.(dataset_name) = ft_selectdata(tmpcfg,data_combined);
end

if numel(block_nums) >= 10
    warning(['The amount of blocks for this participant is equal to or ' ...
        'exceeds 10. Separating the data based on the block number might ' ...
        'cause issues with block arrangement in a combined dataset. Please ' ...
        'make sure when recombining the blocks into a single dataset that ' ...
        'this matches the input dataset for ICA.'])
end

data_no_interactive = cell(2,1);
data_no_interactive{1} = sep_in_blocks;
clear sep_in_blocks
data_no_interactive{2} = data_comp;
clear data_comp
data_no_interactive{3} = data_combined;
clear data_combined