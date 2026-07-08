function answers = data_analysis_answers_v3(subjects,cfg)
% This function has the purpose of disseminating the answers given by
% participants during the task. This function requires a binary answer
% method (e.g. "yes" and "no" ). Output is calculated for the highest
% participant accuracy.
%
% Use as
%
%   [answers] = DATA_ANALYSIS_ANSWERS(subjects,cfg)
% 
% The following inputs are read by the function
%   subjects        = a 1xN string or cell of character vectors
%                     representing the names of participants.
%   cfg.anskey      = a 1x2 string or cell of character vectors
%                     representing the channel names corresponding to the
%                     participant answers. (default = {'STI013','STI014'}). 
%   cfg.soundchan   = a 1x6 string or cell of character vectors representing 
%                     the channel names that signal a sound category
%                     (default: {'STI001','STI002','STI003','STI004', 
%                     'STI005','STI006'}).
%   cfg.trialstart  = a string or character vector representing the channel
%                     name that indicates the start of a trial (default =
%                     'STI008').
%
%   The function outputs the following
%   answers                 = a 1x1 struct with unique fields for each
%                             subject.
%   answers.sub.accuracy    = an Nx1 logical array (where N is the number 
%                             of non-faulty trials) representing correct 
%                             (1) or incorrect (0) answers.
%   answers.sub.accmean     = a double showing the mean of response values
%   answers.sub.accavgper   = a double showing the total average accuracy
%                             percentage.
%   answers.sub.accse       = a double showing the standard error of the
%                             accuracy distribution
%   answers.sub.accci       = a double showing the upper and lower 95%
%                             confidence interval of the accuracy
%                             distribution
%   answers.sub.resptime    = an Nx1 double array (where N is the number of
%                             trials) of the response times.
%   answers.sub.resptimeavg = a double showing the average response time.
%   answers.sub.resptimestd = a double showing the standard deviation of
%                             response times.
%   answers.sub.ping        = a logical showing ping (1) or no ping (0)
%                             subject.
%   answers.sub.numtrials   = a double showing the number of non-faulty
%                             trials.

%% Set the defaults and check for missing inputs
arguments
    subjects (1,:) {mustBeText} = {'bidt','crpo','eigl','eipo','lhko','mrgu','mrhs','urmr'}
    cfg struct = struct('anskey',[],'soundchan',[],'trialstart',[])
end

data_dir = fullfile('..','Data','Raw');
for sub_num = 1:numel(subjects)
    sub = subjects{sub_num};
    subject_dir = fullfile(data_dir,sub);
    if ~isfolder(subject_dir)
        error("Folder %s not found. Please ensure the subject name " + ...
            "corresponds to an existing folder")
    % Folder is empty if it only contains '.' and '..'
    elseif numel(dir(subject_dir)) == 2
        warning("The folder %s is empty. Ignoring this subject",subject_dir)
        subjects(sub_num) = [];
    end
end

if ~issubfield(cfg, 'anskey') || isempty(cfg.anskey)
    anskey_ipt = false;
    cfg.anskey = {'STI013','STI014'};
else
    anskey_ipt = true;
end

if ~issubfield(cfg, 'soundchan') || isempty(cfg.soundchan)
    soundchan_ipt =false;
    cfg.soundchan = {'STI001','STI002','STI003','STI004','STI005','STI006'};
else
    soundchan_ipt = true; 
end

if ~issubfield(cfg, 'trialstart') || isempty(cfg.trialstart)
    trialstart_ipt = false;
    cfg.trialstart = 'STI008';
else
    trialstart_ipt = true;
end

%% Check for errors

% check whether the trialstart input given is of class 'char' as required
if trialstart_ipt
    if ~ischar(cfg.trialstart) && ~isstring(cfg.trialstart)
        warning(['trialstart must be a char and will be switched to default' ...
            ', input is a %s'],class(cfg.trialstart));
        cfg.trialstart = 'STI008';
    elseif isstring(cfg.trialstart)
        if numel(cfg.trialstart) > 1
            warning("Multiple inputs found for cfg.trialstart. Continuing with only the first entry")
            cfg.trialstart = cfg.trialstart(1);
        end
        fprintf("Converting cfg.trialstart string to char \n")
        cfg.trialstart = convertStringsToChars(cfg.trialstart);
    end
end

% check whether the soundchan input given is a 1x6 cell of chars as required
if soundchan_ipt
    if ~iscellstr(cfg.soundchan) 
        warning(['Soundchan must be a cell of chars and will be switched to' ...
            ' default, input is a %s'],class(cfg.soundchan));
        cfg.soundchan = {'STI001','STI002','STI003','STI004','STI005','STI006'};
    end
    for ii = 1:numel(cfg.soundchan)
        if isstring(cfg.soundchan{ii})
            cfg.soundchan{ii} = convertStringsToChars(cfg.soundchan{ii});
        end
    end
end

% check if the anskey input is of class 'cell' and of length 2 as 
% required and else replace with default. Also check if the two entries are
% distinct.
if anskey_ipt
    if ~iscellstr(cfg.anskey) | size(cfg.anskey) ~= ...
            [1,2]
        warning(['input anskey is not a 1x2 cell array of character' ...
        ' vectors but instead a %s of size %.0fx%.0f. Continuing with ' ...
        'default'],class(cfg.anskey),size(cfg.anskey,1),size(cfg.anskey,2));
        cfg.anskey = {'STI013','STI014'};
    elseif cfg.anskey{1} == cfg.anskey{2}
        warning(['the channels given in the anskey are both %s. Continuing ' ...
            'with default'],cfg.anskey{1});
        cfg.anskey = {'STI013','STI014'};
    end
end


% initialize the variables that store information per subject
answers = []; % the final output variable
mean_all_subs = zeros(numel(subjects),1); % the mean accuracy of all 
                                          % subjects.
resptime_all_subs = zeros(numel(subjects),1); % the average response time 
                                              % for all participants
for sub_num = 1:numel(subjects) 
    sub = subjects{sub_num};
    answers.(sub) = [];
    subject_dir = fullfile(data_dir,sub);
    d = dir(subject_dir);
    d = d(~ismember({d.name},{'.','..'}));
    file_names = {d.name};
    
    % find the datasets and their block numbers
    sub_block_files = file_names(contains(file_names,'block'));
    block_nums_str = regexp(sub_block_files,'(?<=block)[0-9][0-9]?','match');
    block_nums = sort(str2double([block_nums_str{:}]));
    
    sorted_file_names = cell(numel(block_nums),1);
    for ii = 1:numel(block_nums)
        block_name = append("block",num2str(block_nums(ii)));
        sorted_file_names{ii} = d(contains({d.name},block_name)).name;
    end
    
    % check whether a .csv file is available for feature task participants.
    % If not, continue as if the participant is a category task participant
    if numel(block_nums) == 10
        session = 'feature';
        try 
            sub_csv_name = file_names{contains(file_names,'.csv')};
        catch
            warning(['No .csv file was found in directory %s. Continuing ' ...
                'without .csv %s'],subject_dir)
            session = 'category';
        end

        if strcmp(session,'feature')
            sub_csv = readtable(fullfile(subject_dir,sub_csv_name));
        end

    elseif numel(block_nums) == 9
        session = 'category';
    else
        warning(['the number of blocks for participant %s is neither equal ' ...
            'to 10 or 9, but is instead %d. Continuing as if the ' ...
            'participant is a category task participant'],sub,numel(block_nums))
        session = 'category';
    end

    % prepare result values
    accuracy_total = false(0,0);
    resp_time_total = [];
    for block_num = block_nums
        % get the number of the trials in the block
        if strcmp(session,'feature')
            trial_nums = (1:60) + ((block_num - 1)*60);
        end

        % get the events from the used dataset
        file_name = sorted_file_names{block_num};
        hdr = ft_read_header(fullfile(subject_dir,file_name));
        event = ft_read_event(fullfile(subject_dir,file_name));

        % make a cell containing all events for later use
        evt_types = cell(length(event),2);
        unused_rows = [];
        for ii = 1:length(event)
            [evt_types{ii,:}] = deal(event(ii).type,event(ii).sample);
            
            % in this case, event rows with event values other than 5 will
            % not be used. Future changes to this function may want to
            % include a change here, as STI101 has specific event values
            % for each event in a trial (e.g. 128 for trial start)
            if event(ii).value ~= 5
                unused_rows(end+1,:) = ii;
            end
        end
        evt_types(unused_rows,:) = [];


        % check whether the trialstart variable is present in the dataset
        if ~ismember(cfg.trialstart,evt_types(:,1))
            if ~trialstart_ipt
                error(['The input file does not contain the default ' ...
                    'cfg.trialstart in event.type']);
            elseif trialstart_ipt
                error(['The input of cfg.trialstart is not present ' ...
                    'in the input file event.type']);
            end
        end

        % check if the anskey variable is in the dataset
        if ~ismember(cfg.anskey{1},evt_types(:,1)) || ~ismember(...
                cfg.anskey{2},evt_types(:,1))
            if ~evtend_ipt
                error(['The input file does not contain the default cfg'...
            '.anskey in event.type']);
            elseif evtend_ipt
                error(['One or more inputs of cfg.anskey are not '...
            'present in the input file event.type'])
            end
        end

        % check whether the soundchan chars are present in the dataset
        for ii = 1:length(cfg.soundchan)
            soundchan = cfg.soundchan(ii);
            if ~ismember(soundchan,evt_types(:,1))
                if ~soundchan_ipt
                    error('The input file does not contain %s in event.type',...
                        soundchan);
                elseif soundchan_ipt
                    error(['The input %s of cfg.soundchan is not present ' ...
                        'in the input file event.type'],soundchan);
                end
            end
        end

        %% Calculating trl

        % preallocate variables for participant response
        resp_types = zeros(sum(count(evt_types(:,1),cfg.trialstart),...
            'all'),1);

        % preallocate variables that will define trial boundaries
        sort_by_trial = cell(sum(strcmp(evt_types(:,1),cfg.trialstart),...
            'all'),1);
        start_row_nums = find(strcmp(evt_types(:,1),cfg.trialstart));
        channel_congruency = cell(sum(strcmp(evt_types(:,1),cfg.trialstart),...
            'all'),3);

        % add trials to sort_by_trial one by one based on the row numbers 
        % of the event start. A trial contains all triggers starting from 
        % one event start to the next.
        for ii = 1:length(start_row_nums)-1
            sort_by_trial{ii,:} = {evt_types{start_row_nums(ii):start_row_nums(ii+1)-1,1}; ...
                evt_types{start_row_nums(ii):start_row_nums(ii+1)-1,2}}';
        end

        % add the final trial, as this has to be ignored in the for loop 
        % due to exceeding bounds.
        sort_by_trial{sum(count(evt_types(:,1),cfg.trialstart),'all'),:} = ...
            {evt_types{start_row_nums(end):end,1};...
            evt_types{start_row_nums(end):end,2}}';

        % fill in the variables that will be used in trl
        for ii = 1:length(sort_by_trial)

            trial = sort_by_trial{ii};

            % get the number at the end of the channel name to define the 
            % sound category (STI001 -> 1, STI002 -> 2 etc.)
            sound_channel_rows = find(ismember(trial(:,1),cfg.soundchan));
            channel_congruency{ii,1} = char(trial(sound_channel_rows(1),1));
            channel_congruency{ii,2} = char(trial(sound_channel_rows(2),1));

            % check whether the trial contains two trial ends (responses)
            if contains(cfg.anskey{1},trial(:,1)) && ...
                    contains(cfg.anskey{2},trial(:,1))
                % check whether the two responses are sequential (both 
                % buttons pressed). This ignores non-sequential button 
                % presses (late response)
                if strcmp(trial{end-1,1},cfg.anskey{1}) || ...
                        strcmp(trial{end-1,1},cfg.anskey{2})
                    warning(['Trial ' num2str(ii) ' has registered two ' ...
                        'responses. The response channel has been set to 2'])
                    resp_types(ii) = 2;
                end
            % check whether the trial contains no responses (too late)
            elseif ~contains(cfg.anskey{1},trial(:,1)) && ...
                    ~contains(cfg.anskey{2},trial(:,1))
                warning(['Trial ' num2str(ii) ' has registered no response. ' ...
                    'The response channel has been set to 3'])
                resp_types(ii) = 3;
            else
                % get which response has been given for the trial
                if strcmp(trial{end,1},cfg.anskey{1})
                    resp_types(ii) = 0;
                elseif strcmp(trial{end,1},cfg.anskey{2})
                    resp_types(ii) = 1;
                end
            end
        end

        %% create output variables
        
        if strcmp(session,'category')
   
            % Find which audio channels contain nonzero values, and 
            % determine the order in which the audio channels were 
            % presented
            for trials = 1:length(channel_congruency(:,1))

                % see whether the channels (and by relation the sound 
                % categories) were the same and add the relevant congruency 
                % to the cell array
                if strcmp(channel_congruency{trials,1},...
                        channel_congruency{trials,2})
                    channel_congruency{trials,3} = "congruent";
                else
                    channel_congruency{trials,3} = "incongruent";
                end
            end

        elseif strcmp(session,'feature')
    
            % prepare variables to distribute
            matches = sub_csv{trial_nums,'is_match'} + 1;
            matches_cong = ["incongruent","congruent"];

            % distribute the variables to the variable channel_congruency
            for ii = 1:length(matches)
                [channel_congruency{ii,3}]   = ...
                    deal(matches_cong(matches(ii)));
            end

        end

        % find the user input and the corresponding answer key

        user_input = cell(length(resp_types),2);
        user_input_nums = resp_types;   % where 0 = cfg.anskey{1} 
                                        % 1 = cfg.anskey{2} 
                                        % 2 = 'two responses' 
                                        % 3 = 'no response'

        % Determine the most likely combination of response button to 
        % response type (congruent or incongruent)

        % start by making a list of the user inputs
    
        for ii = 1:length(user_input)
            if user_input_nums(ii) == 0
                target = cfg.anskey{1};
            elseif user_input_nums(ii) == 1
                target = cfg.anskey{2};  
            elseif user_input_nums(ii) > 1
                target = 'Faulty';
            end
            user_input{ii,1} = target;
        end

        % next make two lists that attribute the chosen channels to the
        % different options of congruency

        option1 = cell(length(user_input),2);
        option2 = cell(length(user_input),2);
        for ii = 1:length(user_input)
            choice_channel = user_input{ii,1};
            if strcmp(choice_channel,'STI013')
                opt1_cong = 'congruent';
                opt2_cong = 'incongruent';
            elseif strcmp(choice_channel,'STI014')
                opt1_cong = 'incongruent';
                opt2_cong = 'congruent';
            elseif strcmp(choice_channel,'Faulty')
                opt1_cong = 'faulty';
                opt2_cong = 'faulty';
            end
            [option1{ii,1:2}] = deal(char(choice_channel),opt1_cong);
            [option2{ii,1:2}] = deal(char(choice_channel),opt2_cong);
        end

        anscorrect = zeros(length(channel_congruency),1);
        options = {option1,option2};
        best_fit = cell(2,2);

        % now calculate the percentage correct answers for both options

        for ii = 1:length(options)
            option = options{ii};
            for jj = 1:length(channel_congruency)
                sound_input = channel_congruency{jj,3};
                user_select = option{jj,2};
                if strcmp(user_select,'faulty')
                    anscorrect(jj) = 0;
                elseif strcmp(sound_input,user_select)
                    anscorrect(jj) = 1;
                else
                    anscorrect(jj) = 0;
                end
            end
            tot_ans_per = (sum(anscorrect)/length(anscorrect))*100;
            [best_fit{ii,1:2}] = deal(option,tot_ans_per);
        end

        % finally, find out which of the two options provides the highest
        % percentage of correct answers, and continue using this 
        if best_fit{1,2} > best_fit{2,2}
            best_opt = string(best_fit{1,1});
        elseif best_fit{1,2} < best_fit{2,2}
            best_opt = string(best_fit{2,1});
        end
        user_input = cell(size(best_opt));
        for ii = 1:length(best_opt)
            [user_input{ii,:}] = deal(string(best_opt{ii,1}),...
                string(best_opt{ii,2}));
        end

        % find out whether the participant answered correctly and the percent of
        % correct responses

        anscorrect = false(length(channel_congruency),1);
        for ii = 1:length(channel_congruency)
            sound_input = channel_congruency{ii,3};
            user_select = user_input{ii,2};
            if strcmp(sound_input,user_select)
                anscorrect(ii) = true;
            else
                anscorrect(ii) = false;
            end
        end

        anscorrect(resp_types == 2 | resp_types == 3) = [];
        accuracy_total = [accuracy_total;anscorrect];

        % calculate the response time in seconds for each trial.

        % create a response time value for trials without response from the 
        % time between the second sound and the start of the next trial, 
        % and round it to one decimal
        soundchan_rows = find(contains(sort_by_trial{1}(:,1),cfg.soundchan));
        sample_endtrial_sound = sort_by_trial{1}{soundchan_rows(2),2};
        sample_begin_next_trial = sort_by_trial{2}{1,2};

        max_response_time = round((sample_begin_next_trial-sample_endtrial_sound)...
            /hdr.Fs,1);

        % make faulty trials empty.
        [sort_by_trial{resp_types == 2 | resp_types == 3}] = deal([]);

        % Calculate the time between the playing of the second sound and 
        % the response by the particpant.
        time_to_respond = zeros(length(sort_by_trial),1);

        for ii = 1:length(sort_by_trial)
            trial = sort_by_trial{ii,:};
            if isempty(trial)
                time_to_respond(ii) = max_response_time;
            else
                % remove the second response at the end if two responses 
                % have been given
                if logical(sum(contains(trial(:,1),'STI013'))) && ...
                    logical(sum(contains(trial(:,1),'STI014')))
                    trial(end,:) = [];
                end
                trl_resp_time = trial{end,2} / hdr.Fs;
                trl_sound_time = trial{end-1,2} / hdr.Fs;
                response_latency = trl_resp_time - trl_sound_time;
                time_to_respond(ii) = response_latency;
            end
        end
        resp_time_total = [resp_time_total;time_to_respond];

    end

    %% Create the output variable
    
    % enter the response accuracy for each trial, the mean, the standard 
    % error of the probability distribution, the 95% confidence interval 
    % and the average percentage into the output variable
    answers.(sub).accuracy = accuracy_total;

    accuracy_total_mean     = mean(accuracy_total);
    mean_all_subs(sub_num)  = accuracy_total_mean;

    % the standard error (SE) describes the uncertainty in the estimation
    % of the true accuracy of the participant. (Because we only have a
    % finite number of trials, we can calculate an "estimate" of the
    % participants true accuracy, which would be found with infinite
    % trials)
    accuracy_total_se       = sqrt((accuracy_total_mean * ... 
        (1-accuracy_total_mean)) / numel(accuracy_total));
    accuracy_total_ci       = accuracy_total_mean + [-1 1] * 1.96 * ... 
        accuracy_total_se;

    accuracy_total_avgper   = mean(accuracy_total)*100;

    answers.(sub).accmean   = accuracy_total_mean;
    answers.(sub).accse     = accuracy_total_se;
    answers.(sub).accci     = accuracy_total_ci;
    answers.(sub).accavgper = accuracy_total_avgper;


    % enter the response time for each trial, the average time
    % and the standard deviation into the output variable
    answers.(sub).resptime = resp_time_total;

    resp_time_avg = sum(resp_time_total)/numel(resp_time_total);
    resptime_all_subs(sub_num)  = resp_time_avg;
    resp_time_std = std(resp_time_total);

    answers.(sub).resptimeavg = resp_time_avg;
    answers.(sub).resptimestd = resp_time_std;

    % enter whether it is a ping or no ping trial into the output 
    % variable
    ping = ismember('STI007',evt_types(:,1));
    answers.(sub).ping = ping;

    % enter the total number of non-faulty trials into the output variable
    num_trials = numel(accuracy_total);
    answers.(sub).numtrials = num_trials;
end

tot_avgper_all_subs     = mean(mean_all_subs)*100;
tot_avgperstd_all_subs  = std(mean_all_subs)*100;

answers.allaccmean      = mean_all_subs;
answers.totaccper       = tot_avgper_all_subs;
answers.totaccperstd    = tot_avgperstd_all_subs;

tot_avgresptime_all_subs    = mean(resptime_all_subs);
tot_avgresptimestd_all_subs = std(resptime_all_subs);

answers.allresptimeavg      = resptime_all_subs;
answers.totresptimeavg      = tot_avgresptime_all_subs;
answers.totresptimestd      = tot_avgresptimestd_all_subs;
