function cfg_default = set_default_cfg_in(ping)
% Creates a default setting for cfg for use in FT_TIMELOCKSTATISTICS in
% combination with the MVPA-Light toolbox. This function is called as a helper function
% in the custom function MVPA_PIPELINE_FULL_CFG, and it is not recommended
% to use this function outside of this intended use.

if ping
    ping_name = "ping";
else
    ping_name = "sound";
end

warning('Default cfg_in for %s timelocked data is being used',ping_name);
cfg                             = [];
cfg.method                      = 'mvpa';
cfg.features                    = 'chan';
cfg.timwin                      = 24;
cfg.tstep                       = 3;
cfg.mvpa                        = [];
cfg.mvpa.classifier             = 'lda';
cfg.mvpa.metric                 = 'accuracy';
cfg.mvpa.preprocess             = {'mnn','average_samples'};
cfg.mvpa.preprocess_param       = {};
cfg.mvpa.preprocess_param{2}    = {'group_size',6};
cfg.mvpa.repeat                 = 100;

if ping
    cfg.mvpa.preprocess_param{1}    = {'target_indices',1:100};
else
    cfg.mvpa.preprocess_param{1}    = {'target_indices',1:125};
end


cfg_default = {cfg};
