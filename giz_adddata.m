function GIZ = giz_adddata(GIZ,DATA,varargin)

if not(exist('GIZ','var'))||isempty(GIZ)
    GIZ = giz_empty;
end


ndat = numel(GIZ.DATA);
if isempty(DATA)
    GIZ.DATA = [];
elseif isnumeric(DATA)
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
    GIZ.DATA{ndat+1} = DATA;
    GIZ.idat = ndat+1;
elseif isstruct(DATA) && isfield(DATA,'setname')
    % assume EEG structure.
    EEG = DATA;clear DATA
    DATA.DAT = EEG.data;
    DATA.dims(1).name = 'channels';
    DATA.dims(1).range = {EEG.chanlocs.labels};
    DATA.dims(1).unit = '\{mu}V';
    DATA.dims(1).etc = EEG.chanlocs;
    DATA.dims(2).name = 'time';
    DATA.dims(2).range = EEG.xmin:1/EEG.srate:EEG.xmax;
    DATA.dims(2).unit = 's';
    DATA.dims(3).name = 'trials';
    DATA.dims(3).range = 1:EEG.trials;
    
    tmp = std_maketrialinfo(struct,EEG);
    DATA.event = tmp.datasetinfo.trialinfo;
    DATA.eventdim = 3;
    
    GIZ.DATA{ndat+1} = DATA;
    GIZ.idat = ndat+1;
elseif isstruct(DATA) && isfield(DATA,'cluster')
    % assume STUDY structure.
    
elseif isstr(DATA) && exist(DATA,'file')
    % assume text file (table)
    % assume MATLAB file
end

