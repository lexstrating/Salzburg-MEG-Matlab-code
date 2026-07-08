## Preprocessing functions and scripts

- `Preprocessing_pipeline_interactive.m` A function that contains the interactive elements of the preprocessing and the modifications that follow it.
In this case the interactive element is the selection of components from Independent Component Analysis (ICA). This function takes the output from
`Preprocessing_pipeline_no_interactive` and removes selected ICA components, removes faulty channels, downsamples from 1000 Hz to 250 Hz, and separates
the dataset based on initial sound category.
- `Preprocessing_pipeline_no_interactive.m` A function that contains the non-interactive elements of the preprocessing. The function applies the following
sequence of preprocessing steps: a zero-phase reverse finite impulse response (FIR) filter with hamming-windowed sinc with delay compensation is applied as
a band-pass filter between 0.5 - 40 Hz to an entire block. Next, the block is separated into trials, which are each baseline corrected over the entire trial.
This is done for all blocks, and all trials from all blocks are then combined. Following this, faulty trials are removed, and ICA is run.
- `Preprocessing_run_script.m` A script to run the preprocessing pipeline on all participants, with faulty trials and channels selected. This script is
intended to run on the High Performance Computing (HPC) cluster of the Donders Centre for Cognitive Neuroscience (DCCN).
- `Preprocessing_run_script_noping.m` Same as `Preprocessing_run_script.m` but only for participants without ping stimuli.
- `Preprocessing_run_script_ping.m` Same as `Preprocessing_run_script.m` but only for participants with ping stimuli.
