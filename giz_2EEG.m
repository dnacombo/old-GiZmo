function EEG = giz_2EEG(GIZ,varargin)

% EEG = giz_2EEG(GIZ,varargin)
% return an EEG structure with desired data in it.
% input argument pairs:
%       what: 'model' or 'DATA'
%       what2: 'fixefs', 'ranefs'...
%       coef: integer, coefficient idx
%       imod: model to pick in (see what)
%       idat: data to pick in (see what)

defifnotexist('GIZ',evalin('caller','GIZ'));

defs.what = 'model';
defs.what2 = 'fixefs';
defs.coef = 1;
defs.idat = GIZ.idat;
defs.imod = GIZ.imod;

s = setdef(vararg2struct(varargin),defs);


switch s.what
    case 'model'
        si = size(GIZ.model(s.imod).(s.what2));
        switch s.what2
            case 'ranefs'
                nm = strrep(GIZ.model(s.imod).info.(s.what2).names,'GiZframe$','');
                if ischar(nm);nm = {nm};end
                nm = repmat(nm,1,size(GIZ.model(s.imod).(s.what2),3)/numel(nm));
                for i = 1:size(nm,2)
                    nm(:,i) = regexprep(nm(:,i),'(.*)',['$1 (' num2str(i) ')']);
                end
            otherwise
                nm = strrep(GIZ.model(s.imod).info.(s.what2).names,'GiZframe$','');
        end
        if numel(nm) ~= size(GIZ.model(s.imod).(s.what2),3)
            error('check Y.dimsm')
        end
        for i = 1:numel(nm)
            EEG(i) = eeg_emptyset;
            EEG(i).data = GIZ.model(s.imod).(s.what2)(:,:,i);
            EEG(i).setname = ['GIZ ' GIZ.model(s.imod).name ' ' s.what2 ' ' nm{i}];
            idat = GIZ.model(s.imod).Y.idat;
            timedim = strcmp({GIZ.DATA{idat}.dims.name},'time');
            isms = strcmp(GIZ.DATA{idat}.dims(timedim).unit,'ms');
            EEG(i).times = GIZ.DATA{idat}.dims(timedim).range / fastif(isms,1000,1);
            chandim = strcmp({GIZ.DATA{idat}.dims.name},'channels');
            EEG(i).chanlocs = GIZ.DATA{idat}.dims(chandim).etc;
            EEG(i).srate = 1./unique(diff(EEG(i).times));
            if numel(EEG(i).srate) > 1
                disp('need to fix that (non unique time steps in EEG.times)')
                keyboard
            end
            EEG(i).xmin = EEG(i).times(1);EEG(i).xmax = EEG(i).times(end);
            EEG(i).pnts = numel(EEG(i).times);
            EEG(i).trials = 1;
            EEG(i).nbchan = numel(EEG(i).chanlocs);
            EEG(i).history = 'Created with giz_2EEG';
        end
    case 'DATA'
        disp('double check that it goes smoothly')
        keyboard
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
        EEG.history = 'Created with giz_2EEG';
    otherwise
        error(['cannot extract ' s.what ' choose ''model'' or ''DATA'''])
end
EEG = eeg_checkset(EEG);

