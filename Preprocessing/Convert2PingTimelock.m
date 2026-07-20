function Convert2PingTimelock(subjects,filenames,savename)

% Converts preprocessed data from being time-locked to sound stimulus onset
% into being time-locked to ping stimulus onset. For participants that were
% not presented with a ping stimulus, a default value of 1.16 seconds from 
% sound stimulus onset is used. The converted data is automatically saved 
% in the same directory as where the original datasets were sourced from
% under a user-defined save name
% 
% use as:
%   Convert2PingTimelock(subjects,filenames,savename);
% 
% Input arguments:
% subjects              = 1xN cell of character vectors representing
%                         identifiers for the subjects.
% filenames             = 1x2 cell of character vectors representing file
%                         names. The first file name should be the dataset
%                         that has to be converted to being time-locked to
%                         ping onset, and the second file name should be
%                         the dataset that contains only stimulus channels.
% savename              = single character vector or string. The converted
%                         data will be saved under this name.


categories = {"objects","instruments","tools","animals","emotional","neutral"};

preproc_dir = fullfile('..\Data','Processing');

data_out = [];
for sub_num = 1:numel(subjects)
    % find and load the original and stimulus datasets that have been
    % separated based on category
    sub = subjects{sub_num};

    % determine whether the subject is a subject who had ping
    % stimuli.
    warning("The ping participants are currently set to 'crpo', 'lhko', and 'mrgu'")
    if any(strcmp(sub,["crpo","mrgu","lhko"]))
        is_ping_participant = true;
    else
        is_ping_participant = false;
    end

    preproc_sub_dir = fullfile(preproc_dir,sub);

    d = dir(fullfile(preproc_sub_dir,'*.mat'));
    relevant_filerows = contains({d.name},filenames);
    d = d(relevant_filerows);

    data_structs = cell(length(d),1);
    for ii = 1:length(d)
        file_dir = fullfile(preproc_sub_dir,d(ii).name);
        % load into a struct for easier access
        data_structs{ii} = load(file_dir);
    end


    data_out.(sub) = [];
    % access the original (and stimulus) data for each category 
    for category_cell = categories
        category = category_cell{:};
        % create a pattern of a regular expression that indicates a
        % variable name that starts with 'data_' followed by the category
        % name and does not end in '_old'.
        pattern = strcat('^(?!.*_old$)data_',category,'\w*$');
        
        fields_orig = fieldnames(data_structs{1});
        desired_field_orig = fields_orig((~cellfun('isempty',regexp(fields_orig,pattern))));
        data_orig = data_structs{1}.(desired_field_orig{:});

        if is_ping_participant
            fields_stim = fieldnames(data_structs{2});
            desired_field_stim = fields_stim{(~cellfun('isempty',regexp(fields_stim,pattern)))};
            data_stim = data_structs{2}.(desired_field_stim);
            stim_channel_rownum = find(strcmp(data_stim.label,"STI007")); % row of ping stimulus channel
        end

            % find the time of stim onset and convert the original data so
            % it is timelocked to stim onset
        
        if is_ping_participant
            time_offsets = zeros(numel(data_orig.trial),1);
            for jj = 1:numel(data_stim.trial)
                stim_onset = find(data_stim.trial{jj}(stim_channel_rownum,:),1);
                stim_onset_time = data_stim.time{jj}(stim_onset);
                % In case there is no ping stimulus at the current (or any)
                % trial, use default value of 1.16 seconds
                if isempty(stim_onset)
                    fprintf(['Subject %s is missing a ping in category' ...
                        '%s, trial %d \n'],sub,category,jj)
                    default_stim_onset_time = 1.16;
                    stim_onset_time = default_stim_onset_time;
                end
                time_offsets(jj) = -stim_onset_time * data_stim.fsample;
            end
        
        else
            % for participants without a ping stimulus, set the offset to
            % the default (1.16 seconds)
            time_offsets = -1.16 * data_orig.fsample;
        end

        % Create a new t = 0 locked to the onset of the ping stimulus (or a
        % default value if not a ping subject)
        cfg = [];
        cfg.offset = time_offsets;

        data_timelock = ft_redefinetrial(cfg,data_orig);

        % For the sake of having equal time limits as required for running
        % MVPA, the time axes need to be slightly downsized to include
        % ubiquitous time limits
        cfg = [];
        cfg.toilim = [-1.60 0.7];

        data_timelock = ft_redefinetrial(cfg,data_timelock);

        result_name = strcat('data_',category,'_ping');
        data_out.(sub).(result_name) = [];
        data_out.(sub).(result_name) = data_timelock;

    end

    % save the newly timelocked data in the same directory
    save_dir = fullfile(preproc_sub_dir,savename);
    subject_savestruct = data_out.(sub);
    save(save_dir,'-struct','subject_savestruct');
end