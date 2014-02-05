function EEG = giz_2EEG(GIZ,varargin)

% EEG = giz_2EEG(GIZ,varargin)
% return an EEG structure with desired data in it.

defifnotexist('GIZ',evalin('caller','GIZ'));

defs.what = 'model';
defs.coef = 1;
defs.idat = GIZ.idat;
defs.imod = GIZ.imod;
defs.contrast = [];

s = setdef(vararg2struct(varargin),defs);

EEG = eeg_emptyset;

switch s.what
    case 'model'
        si = size(GIZ.model(s.imod).coefficients);
        if not(isempty(s.contrast))
            s.contrast = s.contrast(:);
            if not(numel(s.contrast) == si(3))
                error(['Contrast definition']);
            end
            contrast = s.contrast;
        else
            contrast = zeros(si(3),1);
            contrast(s.coef) = 1;
        end            
        contrastmap = repmat(permute(contrast,[3 2 1]),[si(1:2) 1]);
        EEG.data = sum(GIZ.model(s.imod).coefficients .* contrastmap,3);
        nm = giz_coefnames(GIZ);
        if numel(find(contrast)) == 1 && all(contrast > 0)
            EEG.setname = ['GIZ ' GIZ.model(s.imod).name ' - coefficient(s) ' nm{contrast>0}];
        else
            EEG.setname = ['GIZ ' GIZ.model(s.imod).name ' - contrast ' num2str(contrast')];
        end
        timedim = strcmp({GIZ.DATA{GIZ.model(s.imod).idat}.dims.name},'time');
        isms = strcmp(GIZ.DATA{GIZ.model(s.imod).idat}.dims(timedim).unit,'ms');
        EEG.times = GIZ.DATA{GIZ.model(s.imod).idat}.dims(timedim).range / fastif(isms,1000,1);
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
