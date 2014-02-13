function GIZ = giz_adddata(GIZ,DATA,varargin)

defifnotexist('GIZ',evalin('caller','GIZ'));
ndat = numel(GIZ.DATA);

defs.idat = ndat+1;
defs.split = [];
s = setdef(vararg2struct(varargin),defs);

if isempty(DATA)
    GIZ.DATA(s.idat) = [];
elseif isnumeric(DATA)
    disp('Adding matrix data to GIZ.DATA')
    DATA = struct('DAT',DATA);
    for i_dim = 1:ndims(DATA.DAT)
        DATA.dims(i_dim).name = ['dimension' num2str('%02g',i_dim)];
        DATA.dims(i_dim).range = 1:size(DATA.DAT,i_dim);
        DATA.dims(i_dim).unit = 'None';
    end
elseif iscell(DATA) && isstruct(DATA{1}) && isfield(DATA{1},'dims')
    % assume cell of several data (can be of various formats, but is that
    % useful?)
    for i = 1:numel(DATA)
        GIZ = giz_adddata(GIZ,DATA{i});
    end
elseif isstruct(DATA) && isfield(DATA,'dims')
    % assume local format DATA structure
    GIZ.DATA{s.idat} = DATA;
    GIZ.idat = s.idat;
elseif isstruct(DATA) && isfield(DATA,'setname')
    % assume EEG structure.
    EEG = DATA;clear DATA
    disp(['Adding ' EEG.setname ' to GIZ.DATA'])
    DATA.urfname = fullfile(EEG.filepath,EEG.filename);
    DATA.ursetname = EEG.setname;
    
    DATA.DAT = eeg_getdatact(EEG);
    DATA.unit = '\{mu}V';
    DATA.dims(1).name = 'channels';
    DATA.dims(1).range = {EEG.chanlocs.labels};
    DATA.dims(1).unit = '';
    DATA.dims(1).etc = EEG.chanlocs;
    DATA.dims(2).name = 'time';
    DATA.dims(2).range = EEG.xmin:1/EEG.srate:EEG.xmax;
    DATA.dims(2).unit = 's';
    DATA.dims(3).name = 'trials';
    DATA.dims(3).range = 1:EEG.trials;
    
    tmp = std_maketrialinfo(struct,EEG);
    DATA.event = tmp.datasetinfo.trialinfo;
    DATA.eventdim = 3;
    
    GIZ.DATA{s.idat} = DATA;
    GIZ.idat = s.idat;
elseif isstruct(DATA) && isfield(DATA,'cluster')
    % assume STUDY structure.
    
    STUDY = DATA; clear DATA
    if ~isempty([STUDY.design(STUDY.currentdesign).variable.label])
        error('I don''t deal with multiple variable designs. Choose a simple design with NO conditions')
    end
    ALLEEG = s.ALLEEG; s = rmfield(s,'ALLEEG');
    disp(['Adding STUDY ' STUDY.name ' to GIZ.DATA'])
    DATA.urfname = fullfile(STUDY.filepath,STUDY.filename);
    DATA.ursetname = STUDY.name;
    
    % see what's in there
    isread = fieldnames(STUDY.changrp);
    isread = regexp(isread,'(.*)datatrials','tokens');
    isread = isread(~emptycells(isread));
    isread = cellfun(@(x)x{1},isread);
    if isfield(s,'datatype')
        isread = intersect(isread,s.datatype);
    end
    if isempty(isread)
        disp('Please first read STUDY data (using std_readersp or std_readerp)');
        disp('Remember to turn ''singletrial'' ''on''');
        return
    end
    v = struct2vararg(s);
    for iread = 1:numel(isread)
        switch isread{iread}
            case {'ersp' 'erpim' 'itc' 'timef'}
                is3D = 1;
            case {'erp'}
                is3D = 0;
            otherwise
                error('cannot read other than ersp erpim itc timef erp')
        end
        % loop through channels/clusters
        % to retrieve data
        init = 0;
        emptychans = emptycells({STUDY.changrp.([isread{iread} 'datatrials'])});
        firstchan = find(~emptychans,1);
        tmpdat = NaN([sum(~emptychans) size(STUDY.changrp(firstchan).([isread{iread} 'datatrials']){1})],'single');
        for i_chan = find(~emptychans)
            if is3D
                tmpdat(i_chan,:,:,:) = STUDY.changrp(i_chan).([isread{iread} 'datatrials']){1};
            else
                tmpdat(i_chan,:,:) = STUDY.changrp(i_chan).([isread{iread} 'datatrials']){1};
            end
        end
            
        DATA.DAT = tmpdat;
        DATA.unit = '';
        DATA.dims(1).name = 'channels';
        DATA.dims(1).range = {STUDY.changrp(~emptychans).channels};
        DATA.dims(1).unit = '';
        DATA.dims(1).etc = eeg_mergelocs(ALLEEG.chanlocs);
        DATA.dims(1).etc = DATA.dims(1).etc(~emptychans);
        
        if is3D
            DATA.dims(end+1).name = 'frequency';
            DATA.dims(2).range = STUDY.changrp(firstchan).([isread{iread} 'freqs']);
            DATA.dims(2).unit = 'Hz';
        end
        DATA.dims(end+1).name = 'time';
        DATA.dims(end).range = STUDY.changrp(firstchan).([isread{iread} 'times']);
        DATA.dims(end).unit = 'ms';
        DATA.dims(end+1).name = 'trials';
        DATA.dims(end).range = 1:size(tmpdat,numel(DATA.dims));
        
        tmp = std_maketrialinfo(STUDY,ALLEEG);
        % recover event structure from each dataset
        DATA.event = [];
        for idat = 1:numel(tmp.datasetinfo)
            fn = fieldnames(tmp.datasetinfo(idat).trialinfo);
            itris = numel(DATA.event) + (1:numel(tmp.datasetinfo(idat).trialinfo));
            for ifn = 1:numel(fn)
                [DATA.event(itris).(fn{ifn})] = tmp.datasetinfo(idat).trialinfo(1:numel(tmp.datasetinfo(idat).trialinfo)).(fn{ifn});
            end
            datat = repmat({idat},numel(itris),1);
            % create a dataset event with dataset number
            [DATA.event(itris).dataset] = datat{:};
        end
        DATA.eventdim = numel(DATA.dims);
        if not(isempty(s.split))
            if not(isfield(DATA.event,s.split))
                error(['no event named ' s.split '... cannot split the data.']);
            else
                disp(['Splitting DATA by ' s.split])
            end
            splitter = {DATA.event.(s.split)};
            if iscellstr(splitter)
                usplit = unique(splitter);
            else
                splitter = [splitter{:}];
                usplit = unique(splitter);
            end
            for isplit = 1:numel(usplit)
                if iscellstr(splitter)
                    idxsplit = strcmp(splitter,usplit{isplit});
                else
                    idxsplit = splitter == usplit(isplit);
                end
                d = DATA;
                str = ['d.DAT('];
                for i = 1:DATA.eventdim-1
                    str = [str ':,'];
                end
                str = [str 'idxsplit,'];
                for i = DATA.eventdim+1:ndims(DATA.DAT)
                    str = [str ':,'];
                end
                str(end) = [];str = [str ');'];
                d.DAT = eval(str);
                d.event = d.event(idxsplit);
                GIZ.DATA{s.idat+isplit-1} = d;
                GIZ.idat = s.idat;
            end
        else
            GIZ.DATA{s.idat} = DATA;
            GIZ.idat = s.idat;
        end
    end
    
elseif isstr(DATA) && exist(DATA,'file')
    % assume text file (table)
    % assume MATLAB file
end

