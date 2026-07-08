# Salzburg-MEG-Matlab-code
This repository contains custom Matlab functions and scripts used for the preprocessing and analysis of an MEG dataset collected in Salzburg.

It is not recommended to use these functions and scripts outside of their intended purpose nor with data other than that of the aforementioned source. If you wish to make use of one or multiple of these functions and scripts outside of their intended use, it is advised to read through each carefully and adapt where necessary.

These functions and scripts require the Fieldtrip and MVPA-Light toolboxes. Make sure access to these toolboxes is available on your Matlab path.

## Folders, directories and files
The functions and scripts available here work under the assumption that directories are available according to the following:

(PROJECT_NAME)
- Data
  - Processing
    - (sub_name_1)
    - (sub_name_2)
    - (sub_name_n)
      - data_preproc.m (source: `Preprocessing_pipeline_interactive.m` and `Preprocessing_pipeline_no_interactive.m`)
      - data_preproc_ping.m (source: `Convert2PingTimelock.m`)
  - Raw
    - (sub_name_1)
    - (sub_name_2)
    - (sub_name_n)
      - (nums)(sub_name_n)_block1.fif
      - (nums)(sub_name_n)_block2.fif
      - (nums)(sub_name_n)_blockn.fif 
  - Results
    - (sub_name_1)
    - (sub_name_2)
    - (sub_name_n)
      - ping_time-lock
        - stat_(sub_name_n)\_ping\_(result_name).m (source: `MVPA_run_script.m` and `save_MVPA_run_script`)
      - sound_time-lock
        - stat_(sub_name_n)_(result_name).m (source: `MVPA_run_script` and `save_MVPA_run_script`)
- Scripts
  - (script).m
  - (function).m

## Scripts and functions
For the sake of legibility and easy access, scripts and functions are separated into folders in this repository based on their purpose. Each folder will contain its own README.md document detailing the purpose of each script and function that it contains.\
Scripts and functions from this repository are not originally intended to work with separate folders, but are instead intended to be present in the same folder. This is important to note, as many functions contain calls to certain directories starting from the main function/script folder (Scripts).\
For example, a function might call: load('..','Data','Processing','filename'), where '..' refers to one directory up from the current directory.
