## Visualization functions and scripts

- `create_answers_figure.m` A script that creates a figure graphically showing the accuracy scores for the category
and feature task participants. In addition, this script also runs a Welch's t-test to determine whether the mean
accuracy score of the category task participants is lower than the mean accuracy score of the feature task
participants.
> [!NOTE]
> Please be aware that the `create_answers_figure.m` script looks for a file called 'response_statistics.mat' in
> the directory ..\Data\Results that contains the 'answers' struct from `data_analysis_answers_v3`.
- `create_figure.m` A function that creates a figure through `mv_plot_result.m` from the MVPA-light toolbox with
a mask applied from the result of `significance_testing.m` if it is available. It takes a filename and one or two
lists of subjects as inputs and creates a figure from that data. This function only supports the creation of
accuracy-over-time plots. The `significance_testing.m` function is integrated into this function.
- `significance_testing.m` A function that runs a cluster-based permutation test on the input data through
`mv_statistics.m` from the MVPA-Light toolbox. The result is used to apply a mask to the accuracy-over-time
plots created in `create_figure.m`. 
