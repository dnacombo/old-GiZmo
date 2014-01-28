function EEG = giz_2EEG(GIZ,varargin)

% EEG = giz_2EEG(GIZ,varargin)
% return an EEG structure with desired data in it.

defifnotexist('GIZ',evalin('caller','GIZ'));

defs.what = 'model';
defs.coef = 1;
defs.idat = GIZ.idat;
defs.imod = GIZ.imod;

s = setdef(vararg2struct(varargin),defs);

EEG = eeg_emptyset;

switch s.what
    case 'model'
        EEG.data = GIZ.model(s.imod).coefficients(:,:,s.coef);
        EEG.setname = ['GIZ ' GIZ.model(s.imod).name ' - coefficient(s) ' num2str(s.coef)];
        timedim = strcmp({GIZ.DATA{GIZ.model(s.imod).idat}.dims.name},'time');
        EEG.times = GIZ.DATA{GIZ.model(s.imod).idat}.dims(timedim).range;
        chandim = strcmp({GIZ.DATA{GIZ.model(s.imod).idat}.dims.name},'channels');
        EEG.chanlocs = GIZ.DATA{GIZ.model(s.imod).idat}.dims(chandim).etc;
        EEG.srate = 1/unique(diff(EEG.times));
        EEG.xmin = EEG.times(1);EEG.xmax = EEG.times(end);
        EEG.pnts = numel(EEG.times);
        EEG.trials = 1;
        EEG.nbchan = numel(EEG.chanlocs);
    case 'DATA'
        EEG.data = GIZ.DATA{s.idat}.DAT;
        EEG.setname = ['GIZ original data(' GIZ.DATA{s.idat}.ursetname ')'];
        timedim = strcmp({GIZ.DATA{s.idat}.dims.name},'time');
        chandim = strcmp({GIZ.DATA{s.idat}.dims.name},'channels');
        EEG.times = GIZ.DATA{s.idat}.dims(timedim).range;
        EEG.chanlocs = GIZ.DATA{s.idat}.dims(chandim).etc;
        EEG.srate = 1/unique(diff(EEG.times));
        EEG.xmin = EEG.times(1);EEG.xmax = EEG.times(end);
        EEG.pnts = numel(EEG.times);
        EEG.trials = size(EEG.data,3);
        EEG.nbchan = numel(EEG.chanlocs);
end
EEG = eeg_checkset(EEG);
EEG.history = 'Created with giz_2EEG';
