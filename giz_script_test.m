

% EEG = pop_loadset('eeglab_data_epochs_ica.set');

addpath(fileparts(which(mfilename)))

% cd /DATAtest
% EEG = pop_loadset;
cd /Gal_01/Max/Test
% EEG = pop_loadset('APP2_S001_viscor_sacrej_icacor.set');
% cd /Osz_01/Max/test

GIZ = giz_empty;
GIZ = giz_adddata(GIZ,EEG);

GIZ = giz_emptymodel(GIZ);
GIZ.model(GIZ.imod).name = 'test01';

GIZ = giz_model_Y(GIZ,'ReportCorrect');
% GIZ = giz_model_Y(GIZ,{1 'ReportCorrect'});
GIZ = giz_model_X(GIZ,{'StimUnc' 'StimExc' 'LeftRight'});
% GIZ = giz_model_X(GIZ,1);

[ok] = giz_prerunmodel(GIZ);
GIZ = giz_runmodel(GIZ);
GIZ = giz_readmodel(GIZ);

% GIZ = giz_addmodel(GIZ);
% GIZ = giz_model_Y(GIZ,1,3);
% GIZ = giz_model_X(GIZ,{'type'});
% 

