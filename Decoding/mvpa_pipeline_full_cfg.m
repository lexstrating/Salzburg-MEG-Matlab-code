function MVPA_results = mvpa_pipeline_full_cfg(subjects,category,file,cfg_in,ping)

% Reads files in a certain directory and runs an integrated Fieldtrip and
% MVPA-Light pipeline for the analysis of preprocessed MEG data retrieved
% from the Pipeline_trialed_preprocessing_concat_blocks.m script.
% 
% use as:
%   MVPA_results = MVPA_PIPELINE_FULL_CFG(subjects, category, file, cfg, ping)
% 
% Input arguments:
% subjects          = cell containing subject names (e.g. {'crpo','mrgu'}).
% category          = cell containing the names of the categories of the 
%                     desired datasets that will be input in
%                     FT_TIMELOCKSTATISTICS (e.g. "living" for
%                     data_living). This input is also used to define
%                     cfg.design.
% file              = character vector containing a single .mat file name
%                     present in your processed data folder for all
%                     subjects.
% cfg_in            = cell of structs with paramaters used in FT_TIMELOCKSTATISTICS.
%                     Do NOT include cfg.design. This is created based on
%                     the input category.
%                     A default is available.
% ping              = 'true' or 'false' (default = 'false'). Determines
%                     whether to use the ping timelocked dataset (if true)
%                     or the sound timelocked dataset (if false).
% 
% Output:
% stats              = multiple outputs defined by user. Number of outputs
%                     should be equal to number of input subjects. Each is
%                     a Nx1 cell where N is the number of elements of the 
%                     input cfg_in. Each cell contains a struct that is the
%                     result of FT_TIMELOCKSTATISTICS

%% Check the input
arguments
    subjects (1,:) {mustBeText}
    category (1,:) {mustBeText}
    file {mustBeText} = 'data_grad_downsample_category.mat'
    cfg_in (1,:) cell = []
    ping (1,1) logical = false
end
tic
% cfg_in
if isempty(cfg_in)
    cfg_in = set_default_cfg_in(ping);
end

for ii = 1:numel(cfg_in)
    assert(isstruct(cfg_in{ii}),'cfg_in is not a structure variable')
    assert(isfield(cfg_in{ii},'method') && ~isempty(cfg_in{ii}.method), ...
        ['no method has been defined in cfg_in. This will cause issues with ' ...
        'ft_timelockstatistics'])
end

% subjects
assert(~isempty(subjects), 'No subjects have been defined')
assert(iscell(subjects) || ischar(subjects) || isstring(subjects), ...
    'Subjects have not been correctly defined')

if ~iscell(subjects), subjects = {subjects}; end

first_occurence = true;
for ii = 1:numel(subjects)
    if isstring(subjects{ii})
        subjects{ii} = convertStringsToChars(subjects{ii});
        if first_occurence
            fprintf('Converting subject strings to chars \n')
            first_occurence = false;
        end
    end
end

% category
assert(~isempty(category), 'No categories have been defined')
assert(iscell(category) || ischar(category) || isstring(category), ...
    'Categories have not been correctly defined')
if ~iscell(category), category = {category}; end
if numel(category) < 2, error(['Only one category has been defined. At ' ...
        'least two categories need to be defined']); end

first_occurence = true;
for ii = 1:numel(category)
    if isstring(category{ii})
        category{ii} = convertStringsToChars(category{ii});
        if first_occurence
            fprintf('Converting category strings to chars \n')
            first_occurence = false;
        end
    end
end

% file
if isstring(file)
    file = convertStringsToChars(file);
    fprintf('Converting filename string to chars \n')
end

if ~endsWith(file,'.mat')
    if endsWith(file,'.' + lettersPattern)
        error('Input filename does not end in .mat, but in .%s',extractAfter(file,'.'))
    else
        warning("Adding .mat at the end of the input filename %s",file)
        file = append(file,'.mat');
    end
end

for ii = 1:numel(subjects)
    subject = subjects{ii};
    subject_dir = fullfile("..","Data","Processing",subject);
    file_name = fullfile(subject_dir,file);
    assert(isfile(file_name),"Filename %s not found in %s",file,subject_dir)
end
        

%% Initialize the output

MVPA_results = [];
for ii = 1:numel(subjects)
    subject                 = subjects{ii};
    MVPA_results.(subject)  = cell(size(cfg_in));
end
        

%% Run ft_timelockstatistics with input cfg on input subjects for input categories

data_dir        = fullfile('..','Data','Processing'); % Drive containing preprocessed data

for ii = 1:numel(subjects)
    % get the preprocessed datafile
    sub = subjects{ii};
    full_dir        = fullfile(data_dir,sub);
    file_name       = dir(fullfile(full_dir,file)).name;
    desired_file    = fullfile(full_dir,file_name);    

    fprintf('---- loading file %s \n',desired_file);
    Datasets = load(desired_file);

    % create combined datasets of categories and get the number of trials for 
    % each combined category
    Datasets_fieldnames = fieldnames(Datasets);

    if any(strcmp(category,'nonliving'))
        nonliving_rows = contains(Datasets_fieldnames,{'objects','instruments','tools'});
        nonliving_fieldnames = Datasets_fieldnames(nonliving_rows);
        tmpcfg = []; tmpcfg.keepsampleinfo = 'no';
        Datasets.data_nonliving = ft_appenddata(tmpcfg, ...
            Datasets.(nonliving_fieldnames{1}), ...
            Datasets.(nonliving_fieldnames{2}), ...
            Datasets.(nonliving_fieldnames{3}));
    end
    if any(strcmp(category,'living'))
        living_rows = contains(Datasets_fieldnames,{'animals','emotional','neutral'});
        living_fieldnames = Datasets_fieldnames(living_rows);
        tmpcfg = []; tmpcfg.keepsampleinfo = 'no';
        Datasets.data_living = ft_appenddata(tmpcfg, ...
            Datasets.(living_fieldnames{1}), ...
            Datasets.(living_fieldnames{2}), ...
            Datasets.(living_fieldnames{3}));
    end

    % get the name of the category-specific datasets that the user wants
    data_inputs = cell(size(category));
    Datasets_fieldnames = fieldnames(Datasets);
    design_sep = cell(size(category));
    for cat_num = 1:length(category)
        % Find the name of the dataset corresponding to the input category
        Dataset_field = Datasets_fieldnames(contains(Datasets_fieldnames,strcat('data_',category(cat_num))));

        % cat_name should not be empty
        if isempty(Dataset_field)
            error("The dataset for category %s has not been found. Please " + ...
                "check for input error in category or subject",category{cat_num})

        % cat_name should contain only 1 result
        elseif numel(Dataset_field) > 1
            format_str = repmat('%s ',1,numel(Dataset_field));
            format_str = format_str(1:end-1); % remove trailing space
            error("%s is (part of) the name of %d variables: %s",...
                category{cat_num},numel(Dataset_field),...
                sprintf(format_str,Dataset_field{:}))

        else
            data_inputs{cat_num} = Datasets.(Dataset_field{:});
        end
        Ntrials.(category{cat_num}) = numel(data_inputs{cat_num}.trial);
        design_sep{cat_num} = ones(Ntrials.(category{cat_num}),1)*cat_num;
    end

    design = cat(1,design_sep{:});

    for jj = 1:numel(cfg_in)

        cfg_in{jj}.design = design;
        % run ft_timelockstatistics with given inputs
        stat = ft_timelockstatistics(cfg_in{jj},data_inputs{:});
        stat.participant = sub; % add identifier
    
        % save the unique struct variable in the output
        MVPA_results.(sub){jj} = stat;
    end
end
Elapsed_time = toc;
fprintf('Elapsed time: %2f minutes \n',Elapsed_time/60);
