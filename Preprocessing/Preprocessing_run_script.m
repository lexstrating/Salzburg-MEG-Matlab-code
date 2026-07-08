%% Preprocessing_run_script

% coded identifiers of all subjects in alphabetical order
subjects = {'bidt','crpo','eigl','eipo','lhko','mrgu','mrhs','urmr'};

% faulty trials for each subject
faulty_trials_bidt = [99,124,191,408];
faulty_trials_crpo = [];
faulty_trials_eigl = [];
faulty_trials_eipo = [185,215,499,501,504,517];
faulty_trials_lhko = [208,460,496,560];
faulty_trials_mrgu = [];
faulty_trials_mrhs = [];
faulty_trials_urmr = [258,301,373];

% faulty channels for all subjects
faulty_channels = {'-MEG2211','-MEG1532','-MEG0822','-MEG0612'};

cfg = [];
cfg.faulty_trials = {faulty_trials_bidt,faulty_trials_crpo,...
    faulty_trials_eigl,faulty_trials_eipo,faulty_trials_lhko,...
    faulty_trials_mrgu,faulty_trials_mrhs,faulty_trials_urmr};

cfg.faulty_channels = faulty_channels;

% run and save preprocessing
save_directory = fullfile('..','Data','Processing');
cfg_preproc = [];
cfg_preproc.faulty_channels = cfg.faulty_channels;
job = [];
for ii = 1:numel(subjects)
    
    cfg_preproc.faulty_trials = cfg.faulty_trials(ii);
    subject = subjects{ii};
    % run a job on the cluster for 5 hours, and request 30 GB memory
    job.(subject) = qsubfeval(@Preprocessing_pipeline_no_interactive,...
        cfg_preproc,subject,'memreq',30000000000,'timreq',18000);
end
save(fullfile('..','Data','Processing','jobs_non_interactive'),'-struct','job');

%% DO NOT RUN unless the requested jobs have been completed.

% job = load(fullfile('..','Data','Processing','jobs_non_interactive.mat'));
% cfg_preproc = [];
% cfg_preproc.faulty_channels = faulty_channels;
% for ii = 1:numel(fieldnames(job))
%     fieldnames_job = fieldnames(job);
%     subject = fieldnames_job{ii};
%     subject_data = qsubget(job.subject);
%     preproc_subject_data = Preprocessing_pipeline_interactive(cfg_preproc,...
%         subject_data);
%     save(fullfile('..','Data','Processing',subject,'data_preproc'),...
%         '-struct','preproc_subject_data');
% end