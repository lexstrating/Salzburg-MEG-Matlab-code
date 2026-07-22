## Preprocessing functions and scripts

- `Convert2PingTimelock.m` A function that converts preprocessed data from being time-locked to sound onset to being time-locked to ping onset. Slight
deviations in the raw data can occur for the initiation of a ping stimulus after sound onset, resulting in skewed perception times and ping registration
in participants, which this function can take into account.
-  `Pipeline_stimulus_preprocessing.m` A script that runs preprocessing and selects only the stimulus channels. The datasets of each subject are first
separated into trials, and subsequently combined into a single dataset. This dataset is then checked for artefactual trials (note that these should be
the same trials as those removed in the dataset from `Preprocessing_pipeline_no_interactive.m` and `Preprocessing_pipeline_interactive.m`). Next, the
stimulus channels are selected to be kept, the dataset is downsampled from 1000 Hz to 250 Hz, and finally it is separated based on sound category.
- `Preprocessing_pipeline_interactive.m` A function that contains the interactive elements of the preprocessing and the modifications that follow it.
In this case the interactive element is the selection of components from Independent Component Analysis (ICA). This function takes the output from
`Preprocessing_pipeline_no_interactive.m` and removes selected ICA components, removes faulty channels, downsamples from 1000 Hz to 250 Hz, and separates
the dataset based on initial sound category.
- `Preprocessing_pipeline_no_interactive.m` A function that contains the non-interactive elements of the preprocessing. The function applies the following
sequence of preprocessing steps: a zero-phase reverse finite impulse response (FIR) filter with hamming-windowed sinc with delay compensation is applied as
a band-pass filter between 0.5 - 40 Hz to an entire block. Next, the block is separated into trials, which are each baseline corrected over the entire trial.
This is done for all blocks, and all trials from all blocks are then combined. Following this, faulty trials are removed, and ICA is run.
- `Preprocessing_rejection.m` A function that runs all preprocessing steps up to ICA. Options in this function allow the user to interact with preprocessed
datasets in order to identify channels and trials that are faulty. The Fieldtrip function ft_rejectvisual is used for this purpose. It should be noted that
the results of this function are not intended to be used by other functions. Instead, the function serves as a way for a researcher to inspect the data, and
select channels and trials that they believe are noisy or otherwise faulty. These can be noted down and removed in `Preprocessing_pipeline_no_interactive.m`
and `Preprocessing_pipeline_interactive.m`.
- `Preprocessing_run_script.m` A script to run the preprocessing pipeline on all participants, with faulty trials and channels selected. This script is
intended to run on the High Performance Computing (HPC) cluster of the Donders Centre for Cognitive Neuroscience (DCCN).
- `Preprocessing_run_script_noping.m` Same as `Preprocessing_run_script.m` but only for participants without ping stimuli.
- `Preprocessing_run_script_ping.m` Same as `Preprocessing_run_script.m` but only for participants with ping stimuli.
- `function_sound_delay.m` A function that interacts with Fieldtrip's ft_definetrial through cfg.trialfun. This function enables the separation of continuous
data from the study into trials based on sound onset.
> [!WARNING]
> It is recommended that the functions `function_sound_delay.m` and `Preprocessing_rejection.m` are given an update. As they currently stands they are
> functional, but contain questionable practices and/or are lacking in functionality.
> Functionality and error checks can be updated to make the function more user-friendly.\
> For `function_sound_delay.m` the checking of sound categories could also be improved.\
> For `Preprocessing_rejection.m` channel selection for consideration in ft_rejectvisual could be improved to be more interactive for the user (e.g. adding
> a cfg field for relevant channels). Additionally, adding the option to look at ft_databrowser could also be helpful.
