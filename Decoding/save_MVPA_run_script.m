%% save MVPA run script

job_names = fieldnames(job);
faulty_mvpa_runs = {};
for ii = 1:numel(job_names)
    job_name = job_names{ii};
    job_id = job.(job_name);
    try 
        result = qsubget(job.(job_name));
    catch
        warning(['The result for %s has run into an error, continuing ' ...
            'without this result'],job_name);
        result = [];
        faulty_mvpa_runs{end+1} = job_name;
    end

    if isempty(result)
        continue
    end
    % take only from the 6th character onwards. The five characters prior
    % are e.g. 'bidt_' or 'crpo_'
    names = {job_name(6:end)};
    save_mvpa_statistics(names,result);
end
        

    
