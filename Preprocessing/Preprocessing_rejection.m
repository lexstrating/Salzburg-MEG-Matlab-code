function varargout = Preprocessing_rejection(cfg,subjects)

% Reads data from directories and performs a prepared preprocessing 
% pipeline on the input subjects, and removes channels and trials specified
% by the user.
% This function is only to be used to assess the dataset, and to make note of
% faulty channels and trials. The outcomes of this function are not intended
% to be used by any further functions, but rather to allow for the visual
% inspection of trials and/or channels.
% 
% use as:
%   [data_sub1, data_sub2, ...] = Preprocessing_pipeline(cfg, subjects)
% 
% Input arguments:
% cfg
%   .faulty_trials      = an 1xN cell array of faulty trial numbers, where
%                         N corresponds to the number of input subjects.
%                         The rows should correspond with the subject (i.e.
%                         the third entry in the input subjects corresponds
%                         to N = 3 in faulty_trials).
%   .faulty_channels    = a cell array containing the names of faulty
%                         channels, preceded by '-' (e.g. {'-MEG0123'}).
% 
% subjects              = a 1xN cell array of character vectors or string
%                         scalars with the identifiers of each subject.
%                         Alternatively can be set to 'select', in which
%                         case a selection window will appear. (default =
%                         'select')
% 
% Output:
% data                  = multiple outputs specified by user. Number of 
%                         outputs should be equal to number of input
%                         subjects. Each output variable is a struct with 6 
%                         fields, where each struct is a separate category
%                         of sound. Each struct bears the result of a
%                         band-pass filter, trial definition, full trial
%                         baseline correction, faulty trial removal, ICA
%                         correction of ECG and EOG components, channel
%                         selection, downsampling and finally separation
%                         into categories

%% Check inputs
arguments
    cfg struct
    subjects {mustBeText} = 'select'
end

if any(strcmp(subjects,'select'))
    raw_data_dir        = fullfile('..','Data','Raw');
    sub_directory       = dir(raw_data_dir);
    sub_options         = {sub_directory.name};
    select_subject_msg  = "Select subject directories";

    [indx,tf] = listdlg('PromptString',select_subject_msg,'ListString',sub_options);

    if ~tf || isempty(indx)
        error('No subjects have been selected');
    else
        subjects = sub_options(indx);
    end
end

%% Check output
if nargout ~= numel(subjects)
    error(['The number of output variables (%d) does not match the number of ' ...
        'input subjects (%d)'],nargout,numel(subjects))
end

varargout = cell(numel(subjects),1);
%% First get the subject info

% request the subject name
raw_data_dir    = fullfile('..','Data','Raw');
for sub_num = 1:numel(subjects)
    sub = subjects{sub_num};

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

        % demean the trialed data
        tmpcfg              = [];
        tmpcfg.demean       = 'yes';
        tmpcfg.baselinewindow = [-inf 0];
        data_blocks{ii,1}   = ft_preprocessing(tmpcfg,data_trialset_bp);
        clear data_trialset_bp
    end

    % combine the data of all blocks
    tmpcfg = [];
    tmpcfg.keepsampleinfo = 'no'; % sample info cannot be kept because each block starts over
    data_combined = ft_appenddata(tmpcfg,data_blocks{1:end,1});
    clear data_blocks

    %% Remove faulty trials
    faulty_trials = cfg.faulty_trials{sub_num};

    if ~isempty(faulty_trials)
        tmpcfg = [];
        tmpcfg.trials = 1:numel(data_combined.trial);
        tmpcfg.trials(faulty_trials) = [];
        data_combined = ft_selectdata(tmpcfg,data_combined);
    end

%% look at the summary if user wants to
    check_summary_msg = "Look at ft_rejectvisual? Y/N [N]: ";
    check_summary = input(check_summary_msg,"s");

    if isempty(check_summary) | check_summary == "N"
        disp("continuing without ft_rejectvisual")    
    elseif check_summary == "Y"

        tmpcfg = [];

        % have the user select the desired method
        check_method_msg = "Please select method: ";
        methods = {'trial','channel','summary'};
        [indx,tf] = listdlg('PromptString',check_method_msg,'SelectionMode',...
            'single','ListString',methods);

        if ~tf || isempty(indx)
            warning('No method was selected. Continuing without ft_rejectvisual');
        else

            tmpcfg.method = methods{indx};
            tmpcfg.channel = {'MEG',cfg.faulty_channels}; % look at all MEG channels
            tmpcfg.keepchannel = 'no';    % fully remove channels when marked (note that 
                                          % this will also remove non-MEG channels)
            tmpcfg.keeptrial = 'no';       % fully remove trials when marked
            tmpcfg.layout = 'neuromag306planar.lay';
            data_combined = ft_rejectvisual(tmpcfg,data_combined);

        end
        clear check_method_msg methods indx tf
    end
    clear check_summary_msg check_summary 
    varargout{sub_num} = data_combined;
end
