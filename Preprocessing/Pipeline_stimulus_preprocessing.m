%% Preprocessing pipeline get ping time

%% First get the subject info

% request the subject name
raw_data_dir    = fullfile('..\Data','Raw');
sub_d           = struct2table(dir(raw_data_dir));
sub_options     = sub_d.name;
select_subject_msg = "Please select subject: ";
[indx,tf] = listdlg('PromptString',select_subject_msg,'SelectionMode',...
        'single','ListString',sub_options);

if ~tf || isempty(indx)
    error('No subject has been selected');
else
    sub = sub_options{indx};
end

% gain access to the subject files
subj            = [];
subj.rawdir     = fullfile(raw_data_dir,sub);

csv_d           = dir(fullfile(subj.rawdir, '*.csv'));
subj.datatable  = fullfile(csv_d.folder, csv_d.name);

save_data_dir   = fullfile('..\Data','Processing');
subj.savdir     = fullfile(save_data_dir,sub);

d               = dir(fullfile(subj.rawdir, '*.fif'));
data_blocks     = cell(length(d),1);

% clear variables from memory
clear raw_data_dir sub_d sub_options select_subject_msg indx tf sub csv_d

%% Defining trials
for ii = 1:length(d)
    fprintf('currently processing block %d of %d \n',ii,length(d));
    pause(1.2);
    subj.dataset = fullfile(d(ii).folder, d(ii).name);

    % set the trials
    cfg                 = [];
    cfg.dataset         = subj.dataset;
    cfg.datatable       = subj.datatable;
    cfg.trialfun        = 'function_sound_delay';
    cfg                 = ft_definetrial(cfg);
    data_blocks{ii,1}   = ft_preprocessing(cfg);
    
end
% clear variables from memory
clear d

% combine the data of all blocks
cfg = [];
cfg.keepsampleinfo = 'no'; % sample info cannot be kept because each block starts over
data_combined = ft_appenddata(cfg,data_blocks{1:end,1});

% clear variables from memory
clear data_blocks

%% Look for artifacts in databrowser if user wants to
check_databrowser_msg   = "Look at databrowser? Y/N [N]: ";
check_databrowser       = input(check_databrowser_msg,"s");

if isempty(check_databrowser) | check_databrowser == "N"
    
    disp("continuing without databrowser")
    data_clean = data_combined;

elseif check_databrowser == "Y"

    cfg             = [];
    cfg.ylim        = [-1.25e-11 1.25e-11 ];
    cfg             = ft_databrowser(cfg,data_combined);
    cfg_artfctdef   = cfg.artfctdef;

    % turn marked artifacts into NaNs if artifacts have been marked
    if ~isempty(cfg_artfctdef.visual.artifact)
        cfg = [];
        cfg.artifactdef = cfg_artfctdef;
        cfg.artfctdef.reject = 'nan';
        data_clean = ft_rejectartifact(cfg,data_combined);
    else
        data_clean = data_combined;
    end
    clear cfg_artfctdef
end
% clear variables from memory
clear data_combined check_databrowser_msg check_databrowser 

%% look at the summary if user wants to
check_summary_msg = "Look at ft_rejectvisual? Y/N [N]: ";
check_summary = input(check_summary_msg,"s");

if isempty(check_summary) | check_summary == "N"
    disp("continuing without ft_rejectvisual")    
elseif check_summary == "Y"

    cfg = [];

    % have the user select the desired method
    check_method_msg = "Please select method: ";
    methods = {'trial','channel','summary'};
    [indx,tf] = listdlg('PromptString',check_method_msg,'SelectionMode',...
        'single','ListString',methods);

    if ~tf || isempty(indx)
        warning('No method was selected. Continuing without ft_rejectvisual');
    else

        cfg.method = methods{indx};
        cfg.channel = {'MEG*2','MEG*3','-MEG0822','-MEG1532','-MEG0612'};
        cfg.keepchannel = 'yes';    % do not use this method to remove channels
        cfg.keeptrial = 'no';       % fully remove trials when marked
        cfg.layout = 'neuromag306planar.lay';
        data_clean = ft_rejectvisual(cfg,data_clean);

    end
    clear check_method_msg methods indx tf
end
clear check_summary_msg check_summary 

%% Finalize the clean dataset
cfg = [];
cfg.channel = {'STI*'};
data_clean = ft_selectdata(cfg,data_clean);

% downsample from 1000 Hz to 250 Hz for speed
cfg = [];
cfg.resamplefs = 250; % resample to 250 Hz
cfg.detrend = 'no'; % default. Don't want to risk removing relevant trends
cfg.method = 'downsample';
data = ft_resampledata(cfg,data_clean);
clear data_clean

% separate the categories
cfg = [];
cfg.trials = data.trialinfo(:,1) == 1;
data_objects_stim = ft_selectdata(cfg,data);

cfg.trials = data.trialinfo(:,1) == 2;
data_instruments_stim = ft_selectdata(cfg,data);

cfg.trials = data.trialinfo(:,1) == 3;
data_tools_stim = ft_selectdata(cfg,data);

cfg.trials = data.trialinfo(:,1) == 4;
data_animals_stim = ft_selectdata(cfg,data);

cfg.trials = data.trialinfo(:,1) == 5;
data_emotional_stim = ft_selectdata(cfg,data);

cfg.trials = data.trialinfo(:,1) == 6;
data_neutral_stim = ft_selectdata(cfg,data);

% Save the separated data in one .m file (Note: the data is separated based
% on category first to reduce the variable file-size. Saving variables over
% a certain amount requires the use of a different saving method '-v7.3'.
% While there is an option to specify '-nocompression', separating the data
% into separate parts can use the default '-v7' saving method.
% Additionally, further analysis requires splitting up the data into
% separate categories. Saving the data as separate categories can therefore
% be justified.
savefile_name = append(subj.savdir,'\stimulus_time_check');
fprintf("Saving data as %s \n",savefile_name);
save(savefile_name,'data_objects_stim','data_instruments_stim','data_tools_stim',...
    'data_animals_stim','data_emotional_stim','data_neutral_stim');