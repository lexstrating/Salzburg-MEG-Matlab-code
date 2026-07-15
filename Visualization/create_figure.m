function MVPA_fig = create_figure(filename,combi_1,combi_2)
% This function creates a new figure of MVPA results. It takes a file name
% and subject combinations that will be represented in a figure created by
% the function MV_PLOT_RESULT from the MVPA-Light toolbox.
% 
%  use as:
% 
%   MVPA_fig = CREATE_FIGURE(filename,combi_1,combi_2)
% 

arguments
    filename {mustBeText}
    combi_1 cell {mustBeText}
    combi_2 cell {mustBeText} = cell(0,0)
end

% create the significance mask for the coming figure. The
% significance_testing function takes the same inputs and makes the same
% checks, hence it is possible to start with siginficance testing at the
% very start
if ~isempty(combi_2)
    % it can occur that no significant cluster is found, in which case an
    % error is thrown.
    try
        significance_stat = significance_testing(filename,combi_1,combi_2);
    catch
        warning(['An error occured when trying to run significance testing.' ...
            ' No mask will be applied'])
        significance_stat = [];
    end
else
    % it can occur that no significant cluster is found, in which case an
    % error is thrown.
    try
        significance_stat = significance_testing(filename,combi_1);
    catch
        warning(['An error occured when trying to run significance testing.' ...
            ' No mask will be applied'])
        significance_stat = [];
    end
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
subs_1 = ''; % prepare for the legend names
for ii = 1:numel(combi_1)
    sub = combi_1{ii};
    subs_1 = append(subs_1,sub,' ');
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
    subs_2 = '';
    for ii = 1:numel(combi_2)
        sub = combi_2{ii};
        subs_2 = append(subs_2,sub,' ');
        data_dir = fullfile('..','Data','Results',sub,time_lock);

        d = dir(fullfile(data_dir,file_with_wildcards));
        sub_filename = d.name;
        stat_result = load(fullfile('..','Data','Results',sub,time_lock,...
            sub_filename));
        result_fieldname = fieldnames(stat_result);
        stat_combi_2{ii} = stat_result.(result_fieldname{1}).mvpa;
    end
end

% create the average result of MVPA for the first input participants
stat_avg_1 = mv_combine_results(stat_combi_1,'average');
stat_avg_1.name = append(subs_1,strrep(filename,'_',' '));

% if they were provided, create the average result of of MVPA for the
% second input participants
if ~isempty(combi_2)
    stat_avg_2 = mv_combine_results(stat_combi_2,'average');
    stat_avg_2.name = append(subs_2,strrep(filename,'_',' '));
    
    % create the figure input for separate plots for the first and second
    % input participants
    fig_input = mv_combine_results({stat_avg_1,stat_avg_2},'merge');
    
else
    % create the figure input for a single plot for the first input
    % participants.
    fig_input = stat_avg_1;
end
% the time field in the MVPA results should be the same for all subjects.
% Hence, it does not matter which stat_result struct is used to access the
% time field.
time_input  = stat_result.(result_fieldname{1}).time; 

% Create the figure
MVPA_fig = mv_plot_result(fig_input,time_input);

% Instead of marking the line bold where it is significant as is done by
% specifying the 'mask' key-value pair in mv_plot_result, significance is
% marked with a line at that location. If no significant cluster is found,
% no line is provided
if ~isempty(significance_stat) && ...
        ~isempty(unique(significance_stat.mask_with_cluster_numbers(...
        significance_stat.mask_with_cluster_numbers ~= 0)))

    % loop over all unique significant clusters
    for ii = unique(significance_stat.mask_with_cluster_numbers(...
            significance_stat.mask_with_cluster_numbers ~= 0))
        
        % find the timepoints where the significant cluster is
        significance_mark = time_input(...
            significance_stat.mask_with_cluster_numbers == ii);
        
        % plot a line
        plot(significance_mark,(ones(numel(significance_mark),1)*0.7),'-k',...
            'LineWidth',3)
    end
end

% add black dashed lines showing the ping and sound onset times (in this 
% case, 1.16 seconds between both onsets)
if contains(filename,'ping')
    xline(-1.16,'--k',{'Sound', 'onset'},'LineWidth',1)
    xline(0,'--k',{'Ping', 'onset'},'LineWidth',1)
else
    xline(1.16,'--k',{'Ping', 'onset'},'LineWidth',1)
    xline(0,'--k',{'Sound', 'onset'},'LineWidth',1)
end
