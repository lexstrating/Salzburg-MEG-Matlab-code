## Visualization functions and scripts

- `create_figure.m` A function that creates a figure through `mv_plot_result.m` from the MVPA-light toolbox with
a mask applied from the result of `significance_testing.m` if it is available. It takes a filename and one or two
lists of subjects as inputs and creates a figure from that data. This function only supports the creation of
accuracy-over-time plots. The `significance_testing.m` function is integrated into this function.
- `significance_testing.m` A function that runs a cluster-based permutation test on the input data through
`mv_statistics.m` from the MVPA-Light toolbox. The result is used to apply a mask to the accuracy-over-time
plots created in `create_figure.m`. 
