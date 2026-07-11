## Decoding functions and scripts

- `MVPA_run_script.m` a script that runs the function `mvpa_pipeline_full_cfg.m` with certain parameters. The function runs through the
High Performance Computing (HPC) cluster of the Donders Centre for Cognitive Neuroscience (DCCN). This script is meant to be adapted to
suit the needs of the user.
- `mvpa_pipeline_full_cfg.m` a function that runs MVPA analysis with input configuration (cfg) parameters on all input files for all input
subjects, comparing the input classes. A default cfg is available through `set_default_cfg_in.m`. It is possible to do multiple MVPA runs
through this function by inputting multiple cfg structs through a cell vector.
- `save_MVPA_run_script.m` a script that saves the MVPA jobs performed on the HPC cluster through `MVPA_run_script.m` to the relevant
folders in Data\Results. This script makes use of `save_mvpa_statistics.m`.
- `save_mvpa_statistics.m` a function that saves the output of `mvpa_pipeline_full_cfg.m` under input names. The files are saved to the
relevant folders in Data\Results.
- `set_default_cfg_in.m` a function that outputs a default cfg struct for use in `mvpa_pipeline_full_cfg.m`. Different options are available
for use with ping time-locked or sound time-locked datasets.
