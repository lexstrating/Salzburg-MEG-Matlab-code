%% Create answers figure

% In this case, there are two distinct groups. One group that has done a 
% 'category' task, and another that has done a feature task. The purpose of
% this script is to assess the accuracy scores of the two groups, calculate 
% whether the difference between the two groups is significant, and plot an
% errorbar graph depicting the accuracy scores and standard deviation of
% the two groups

%% Initialize
% load the answer data of the participants. This should load in a struct
% named 'answers'.
load(fullfile('..','Data','Results','response_statistics.mat'));

% initiate an empty struct
cat_feat = [];

%% get the data of the category and feature task participants

% vector of doubles of the accuracy score of category participants
cat_feat.response_accuracy_category = [answers.crpo.accmean,...
    answers.eigl.accmean,answers.mrgu.accmean,answers.mrhs.accmean,...
    answers.urmr.accmean];

% vector of doubles of the accuracy score of feature participants
cat_feat.response_accuracy_feature = [answers.bidt.accmean,...
    answers.eipo.accmean,answers.lhko.accmean];

% double of the mean accuracy score of category participants
cat_feat.response_accuracy_average_category = mean([answers.crpo.accmean,...
    answers.eigl.accmean,answers.mrgu.accmean,answers.mrhs.accmean,...
    answers.urmr.accmean]);

% double of the mean accuracy score of feature participants
cat_feat.response_accuracy_average_feature = mean([answers.bidt.accmean,...
    answers.eipo.accmean,answers.lhko.accmean]);

% double of the standard deviation of the mean accuracy score of category 
% participants
cat_feat.response_accuracy_standarddev_category = std([...
    answers.crpo.accmean,answers.eigl.accmean,answers.mrgu.accmean,...
    answers.mrhs.accmean,answers.urmr.accmean]);

% double of the standard deviation of the mean accuracy score of feature 
% participants
cat_feat.response_accuracy_standarddev_feature = std([answers.bidt.accmean,...
    answers.eipo.accmean,answers.lhko.accmean]);

%% Run Welch's t-test

% run a one-sided, two-sample t-test assuming unequal variances. In this
% case, the alternative hypothesis that is being tested is that the mean of
% the accuracy score of category task participants is lower than the mean
% of the accuracy score of the feature task participants.

[h,p] = ttest2(cat_feat.response_accuracy_category,...
    cat_feat.response_accuracy_feature,'Tail','left','Vartype','unequal');

cat_feat.Welch_ttest_one_sided_two_sample_p = p;

%% Create the figure
figure

errorbar([cat_feat.response_accuracy_average_category,...
    cat_feat.response_accuracy_average_feature],...
    [cat_feat.response_accuracy_standarddev_category,...
    cat_feat.response_accuracy_standarddev_feature],'o');

% leave room at the horizontal edges
xlim([0,3]);
% leave room at the vertical edges
ylim([0.5,1.0]);

% rename the x-axis values and label the x-axis
set(gca,'Xtick',[1,2],'Xticklabel',{'category','feature'})
xlabel('Task')

% reduce the amount of units on the y-axis and label the y-axis
set(gca,'Ytick',0.5:0.1:1)
ylabel('Accuracy score')

% make a text banner for the values of the mean and standard deviation of 
% the category and feature task and add them to the figure
txt_cat = sprintf('- %.3f %s %.3f',...
    cat_feat.response_accuracy_average_category,char(177),...
    cat_feat.response_accuracy_standarddev_category);

txt_feat = sprintf('- %.3f %s %.3f',...
    cat_feat.response_accuracy_average_feature,char(177),...
    cat_feat.response_accuracy_standarddev_feature);

text(1.1,cat_feat.response_accuracy_average_category,txt_cat)
text(2.1,cat_feat.response_accuracy_average_feature,txt_feat)
