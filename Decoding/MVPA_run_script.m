%% MVPA run script

subjects = {'bidt','crpo','eigl','eipo','lhko','mrgu','mrhs','urmr'};
% cat_1 = {'objects','animals'};
% cat_1_name = 'objects_v_animals_rep100';
% cat_2 = {'objects','emotional'};
% cat_2_name = 'objects_v_emotional_rep100';
% cat_3 = {'objects','neutral'};
% cat_3_name = 'objects_v_neutral_rep100';
% cat_4 = {'instruments','animals'};
% cat_4_name = 'instruments_v_animals_rep100';
% cat_5 = {'instruments','emotional'};
% cat_5_name = 'instruments_v_emotional_rep100';
% cat_6 = {'instruments','neutral'};
% cat_6_name = 'instruments_v_neutral_rep100';
% cat_7 = {'tools','animals'};
% cat_7_name = 'tools_v_animals_rep100';
% cat_8 = {'tools','emotional'};
% cat_8_name = 'tools_v_emotional_rep100';
% cat_9 = {'tools','neutral'};
% cat_9_name = 'tools_v_neutral_rep100';
% cat_10 = {'nonliving','living'};
% cat_10_name = 'preproc_default_rep100';

cat_11 = {'objects','instruments','tools','animals','emotional','neutral'};
cat_11_name = 'confusion_all_v_all';
categories = {cat_11};
category_names = {cat_11_name};
% categories = {cat_1,cat_2,cat_3,cat_4,cat_5,cat_6,cat_7,cat_8,cat_9,cat_10};
% category_names = {cat_1_name,cat_2_name,cat_3_name,cat_4_name,cat_5_name,...
%     cat_6_name,cat_7_name,cat_8_name,cat_9_name,cat_10_name};

cfg_1                             = [];
cfg_1.method                      = 'mvpa';
cfg_1.features                    = 'chan';
cfg_1.avgovertime                 = 'yes';
cfg_1.latency                     = [0,0.5];
cfg_1.mvpa                        = [];
cfg_1.mvpa.classifier             = 'multiclass_lda';
cfg_1.mvpa.metric                 = 'confusion';
cfg_1.mvpa.repeat                 = 100;

cfg_in = {cfg_1};

file = {'data_preproc.mat','data_preproc_ping.mat'};
job = [];
for ii = 1:numel(subjects)
    subject = subjects(ii);
    for jj = 1:numel(file)
        input_filename = file{jj};
        if contains(input_filename,'ping')
            ping_name = '_ping_';
            ping = true;
        else
            ping_name = '_';
            ping = false;
        end
        for hh = 1:numel(categories)
            category = categories{hh};
            category_name = category_names{hh};
            sub_id = append(subject{:},ping_name,category_name);
            job.(sub_id) = qsubfeval(@mvpa_pipeline_full_cfg,subject,category,input_filename,cfg_in,ping,'memreq',8000000000,'timreq',3600);
        end
    end
end

save(fullfile('..','Data','Results','jobs_mvpa'),'-struct','job');
