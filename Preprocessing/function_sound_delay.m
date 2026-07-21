function trl = function_sound_delay(cfg)

% This function is designed for use with the Fieldtrip function
% FT_DEFINETRIAL.
% 
% It is designed around .fif MEG data that contains activity in channels 
% that signal for trial details
%
% TRIAL CHANNELS DETAILS
%   trigger channel:    trigger value:  trigger type:
%   STI001              1               "objects"
%   STI002              2               "instruments"
%   STI003              4               "tools"
%   STI004              8               "animals"
%   STI005              16              "emotional"
%   STI006              32              "neutral"
%   STI007              64              "ping"
%   STI008              128             "trial-start"
%   STI009              256
%   STI010              512
%   STI011              1024
%   STI012              2048
%   STI013              4096            "trial-response"
%   STI014              8192            "trial-response"
%   STI015              16384
%   STI016              32768
%   STI101              65536           "all_triggers"
%   SYS201              131072
%
% this function requires the following fields
%   cfg.dataset             =   string with the filename
%   cfg.datatable           =   string with filename of a table containing
%                               information on the sound category presented
%                               for each trial
%   cfg.trialdef.eventstart =   string with the channel name that signals a
%                               trial start (default: 'STI008')
%   cfg.trialdef.eventvalue =   double of the relevant event value
%                               (default: 5)
%   cfg.trialdef.soundchan  =   1x6 cell of character vectors with the 
%                               channel names that signal a sound category
%                               (default: {'STI001','STI002','STI003',
%                               'STI004','STI005','STI006'}
%   cfg.trialdef.prestim    =   double of the time in seconds before the
%                               trial start to include a longer period
%                               (default: 0.5)
%   cfg.trialdef.poststim   =   double of the time in seconds to define the
%                               trial end
%                               (default: 1.9)
%
%
% The result of this function will be a trl Nx5 matrix or table described
% in FT_DEFINETRIAL. N is the number of trials, and the 5 columns detail
% sample indices at the start of trials, sample indices at the end of
% trials, offset of the trigger, the memory item trigger channel number,
% and the block number respectively.
%
% This function is to be defined in cfg.trialfun for use in FT_DEFINETRIAL. 

hdr     = ft_read_header(cfg.dataset);
event   = ft_read_event(cfg.dataset);

if ~issubfield(cfg,'trialdef.prestim')
    cfg.trialdef.prestim = 0.5;
else
    warning(['trialdef.prestim has been defined by user. Please make sure' ...
        ' that this value is correct']);
end

if ~issubfield(cfg,'trialdef.poststim')
    cfg.trialdef.poststim = 1.9;
else
    warning(['trialdef.poststim has been defined by user. Please make sure' ...
        ' that this value is correct']);
end

if ~issubfield(cfg,'trialdef.eventvalue')
    cfg.trialdef.eventvalue = 5;
else
    warning(['trialdef.eventvalue has been defined by user. Please make ' ...
        'sure that this value is correct.']);
end

% make a cell containing all events for later use

evt_types = cell(length(event),2);
unused_rows = [];
for ii = 1:length(event)
    [evt_types{ii,:}] = deal(event(ii).type,event(ii).sample);
    if event(ii).value ~= cfg.trialdef.eventvalue
        unused_rows(end+1,:) = ii;
    end
end
evt_types(unused_rows,:) = [];
%% Check for inputs and errors

% check if the event start is given and else add 'STI008'
if ~issubfield(cfg, 'trialdef.eventstart')
    cfg.trialdef.eventstart = 'STI008';
    warning('No eventstart input, continuing with STI008');
    evtstart_ipt = 0; % this is 0 if cfg did not contain an eventstart input
else
    evtstart_ipt = 1; % this is 1 if cfg did contain an eventstart input
end
warning('on','backtrace');

% check whether the input given is of class 'char' as required
if evtstart_ipt
    if ~ischar(cfg.trialdef.eventstart)
        warning(['Eventstart must be a char and will be switched to default' ...
            ', input is a %s'],class(cfg.trialdef.eventstart));
        cfg.trialdef.eventstart = 'STI008';
    end
end

% check whether the eventstart variable is present in the dataset
if ~ismember(cfg.trialdef.eventstart,evt_types(:,1))
    if ~evtstart_ipt
        error(['The input file does not contain the default cfg.trialdef'...
            '.eventstart in event.type']);
    elseif evtstart_ipt
        error(['The input of cfg.trialdef.eventstart is not present ' ...
            'in the input file event.type']);
    end
end

% check if the sound channels are given and else add the default 1x6 cell
if ~issubfield(cfg, 'trialdef.soundchan')
    cfg.trialdef.soundchan = {'STI001','STI002','STI003','STI004','STI005'...
        ,'STI006'};
    warning(['No soundchan input, continuing with STI001, STI002, STI003, ' ...
        'STI004, STI005 and STI006']);
    soundchan_ipt = 0; % this is 0 if cfg did not contain a soundchan input
else
    soundchan_ipt = 1; % this is 1 if cfg did contain a soundchan input
end

% check whether the input given is a 1x6 cell of chars as required
if soundchan_ipt
    if ~iscellstr(cfg.trialdef.soundchan) | size(cfg.trialdef.soundchan) ...
            ~= [1,6]
        warning(['Soundchan must be a 1x6 cell of chars and will be switched to' ...
            ' default, input is a %s of size %dx%d'],...
            class(cfg.trialdef.soundchan),size(cfg.trialdef.soundchan,1),...
            size(cfg.trialdef.soundchan));
        cfg.trialdef.soundchan = {'STI001','STI002','STI003','STI004',...
            'STI005','STI006'};
    end
end

% check whether the soundchan chars are present in the dataset
for ii = 1:length(cfg.trialdef.soundchan)
    soundchan = cfg.trialdef.soundchan(ii);
    if ~ismember(soundchan,evt_types(:,1))
        if ~soundchan_ipt
            error('The input file does not contain %s in event.type',...
                soundchan);
        elseif soundchan_ipt
            error(['The input %s of cfg.trialdef.soundchan is not present ' ...
                'in the input file event.type'],soundchan);
        end
    end
end

% check whether the datatable has been given, otherwise return error.
if ~issubfield(cfg,'datatable') || isempty(cfg.datatable)
    error('No datatable was input. Please input a valid .csv file')
elseif contains(cfg.datatable,'feature')
    feature = true;
else
    feature = false;
end
input_csv = readtable(cfg.datatable);

%% Calculating trl

% preallocate variables
trl = zeros(sum(count(evt_types(:,1),cfg.trialdef.eventstart),...
    'all'),5);

% offset (as used by ft_preprocessing) is set to 0

% preallocate variables that will define trial boundaries
sort_by_trial = cell(sum(count(evt_types(:,1),cfg.trialdef.eventstart),'all'),1);
start_row_nums = find(count(evt_types(:,1),cfg.trialdef.eventstart));

% add trials to sort_by_trial one by one based on the row numbers of the
% event start. A trial contains all triggers starting from one event start
% to the next.
for ii = 1:length(start_row_nums)-1
    sort_by_trial{ii,:} = {evt_types{start_row_nums(ii):start_row_nums(ii+1)-1,1}; ...
        evt_types{start_row_nums(ii):start_row_nums(ii+1)-1,2}}';
end

% add the final trial, as this has to be ignored in the for loop due to
% exceeding bounds.
sort_by_trial{sum(count(evt_types(:,1),cfg.trialdef.eventstart),'all'),:} = {evt_types{start_row_nums(end):end,1}; ...
        evt_types{start_row_nums(end):end,2}}';

% get the block number of the input cfg.dataset
if ~feature
    blocknumpos = strfind(cfg.dataset,'block') + length('block');
    blocknum    = str2double(cfg.dataset(blocknumpos));
else
    blocknumpos = strfind(cfg.dataset,'block') + length('block');
    if cfg.dataset(blocknumpos+1) == "."
        blocknum = str2double(cfg.dataset(blocknumpos));
    else
        blocknum = str2double(cfg.dataset(blocknumpos:blocknumpos+1));
    end
end

% get the trial numbers per block
block_nums = [1,60;61,120;121,180;181,240;241,300;301,360;361,420;421,480;...
    481,540;541,600];
block_trials = block_nums(blocknum,1):block_nums(blocknum,2);

% preallocate trigger-value category pairs. Column 1 contains category
% number, column 2 contains associated trigger value.
if ~feature
    trigger_category = [1,1;2,4;3,16;4,2;5,8;6,32];
    warning(['This is data from the category task. Please check the .csv ' ...
        'file for the correspondence between trigger category and trigger ' ...
        'value'])
end

% fill in the variables that will be used in trl
for ii = 1:length(sort_by_trial)

    trial           = sort_by_trial{ii};
    sound_rows      = find(contains(trial(:,1),cfg.trialdef.soundchan));
    sample_begin    = trial{sound_rows(1),2} - cfg.trialdef.prestim * hdr.Fs;
    sample_end      = trial{sound_rows(1),2} + cfg.trialdef.poststim * hdr.Fs;
    offset          = -cfg.trialdef.prestim*hdr.Fs;
    
    if feature
        sound_category  = input_csv{block_trials(ii),'category'};
    else
        trigger_value = input_csv{block_trials(ii),'trigger_mem_item'};
        trigger_row = trigger_category(:,2) == trigger_value;
        sound_category = trigger_category(trigger_row,1);
    end

    trl(ii,:) = [round([sample_begin,sample_end,offset]) sound_category ...
        blocknum];
end