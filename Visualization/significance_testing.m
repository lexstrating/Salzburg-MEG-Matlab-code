function significance_stat = significance_testing(filename,combi_1,combi_2)



arguments
    filename {mustBeText}
    combi_1 cell {mustBeText}
    combi_2 cell {mustBeText} = cell(0,0)
end

% from the file name, see whether to look in the ping_time-locked or
% sound_time-locked folders
if contains(filename,'ping')
    time_lock = 'ping_time-locked';
else
    time_lock = 'sound_time-locked';
end

% use wildcards with the filename to allow the dir function to find the
% relevant file irrespective of what comes before or after the input file 
% name.
file_with_wildcards = append('*',filename,'*');

% combine the MVPA statistics of the first input participants
stat_combi_1 = cell(numel(combi_1),1);
for ii = 1:numel(combi_1)
    sub = combi_1{ii};
    data_dir = fullfile('..','Data','Results',sub,time_lock);

    d = dir(fullfile(data_dir,file_with_wildcards));
    sub_filename = d.name;
    stat_result = load(fullfile('..','Data','Results',sub,time_lock,...
        sub_filename));
    result_fieldname = fieldnames(stat_result);
    stat_combi_1{ii} = stat_result.(result_fieldname{1}).mvpa;
end

% if they were provided, combine the MVPA statistics of the second input
% participants
if ~isempty(combi_2)
    stat_combi_2 = cell(numel(combi_2),1);
    for ii = 1:numel(combi_2)
        sub = combi_2{ii};
        data_dir = fullfile('..','Data','Results',sub,time_lock);

        d = dir(fullfile(data_dir,file_with_wildcards));
        sub_filename = d.name;
        stat_result = load(fullfile('..','Data','Results',sub,time_lock,...
            sub_filename));
        result_fieldname = fieldnames(stat_result);
        stat_combi_2{ii} = stat_result.(result_fieldname{1}).mvpa;
    end
end

% For one reason or another, Fieldtrip converts the perf and perf_std
% fields of MVPA into a cell. For use in mv_statistics, perf and perf_std
% cannot be cells
for ii = 1:numel(stat_combi_1)

    if iscell(stat_combi_1{ii}.perf)
        stat_combi_1{ii}.perf = stat_combi_1{ii}.perf{:};
    end

    if iscell(stat_combi_1{ii}.perf_std)
        stat_combi_1{ii}.perf_std = stat_combi_1{ii}.perf_std{:};
    end
end

% if they were provided, convert the perf and perf_std fields of the MVPA
% statistics of the second input participants from cells to doubles
if ~isempty(combi_2)
    for ii = 1:numel(stat_combi_2)

        if iscell(stat_combi_2{ii}.perf)
            stat_combi_2{ii}.perf = stat_combi_2{ii}.perf{:};
        end

        if iscell(stat_combi_2{ii}.perf_std)
            stat_combi_2{ii}.perf_std = stat_combi_2{ii}.perf_std{:};
        end
    end
end

% the default input of cfg for mv_statistics
cfg = [];
cfg.test = 'permutation';
cfg.n_permutations = 10000;
cfg.correctm = 'cluster';   % permutation testing with cluster correction.
cfg.clusterstatistic = 'maxsum';
cfg.alpha = 0.05;
cfg.clustercritval = 1.96;  % critical z-value for two-sided Wilcoxon 
                            % sign-rank test at uncorrected p-value of 0.05
cfg.statistic = 'wilcoxon';
cfg.null = 0.5; % null-value for within-subject design with two classes
if ~isempty(combi_2)
    cfg.design = 'between';
    stat_input = [stat_combi_1; stat_combi_2];
    cfg.group = [ones(numel(stat_combi_1),1);2*ones(numel(stat_combi_2),1)];
else
    cfg.design = 'within';
    stat_input = stat_combi_1;
end

% run mv_statistics and get the result
significance_stat = mv_statistics(cfg,stat_input);
