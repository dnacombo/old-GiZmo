function giz_topo(GIZ,varargin)

% giz_topo(GIZ,varargin)
% plot topographical representations of current model.
% 
% inputs:
%       'what': string: 'DATA' or 'model' (default : 'model')
%       'coef': if plotting model: coefficient number or name to plot. 
%       'times': vector of times to plot
% optional inputs:
%       'idat': idat to work with
%       'imod': imod to work with

defs.what = 'model';
defs.coef = 1;
defs.times = [0 100 200];
defs.idat = GIZ.idat;
defs.imod = GIZ.imod;

s = setdef(vararg2struct(varargin),defs);

switch s.what
    case 'DATA'
        data = GIZ.DATA{s.idat}.DAT;
        tit = ['Data (' num2str(s.idat) ')'];
    case 'model'
        if ~isnumeric(s.coef)
            s.coef = find(regexpcell(GIZ.model(s.imod).info.coefs.names,s.coef),1);
        end
        data = GIZ.model(s.imod).coefficients(:,:,s.coef);
        tit = [GIZ.model(s.imod).info.coefs.names{s.coef}];
    otherwise
        error('I can plot only DATA or model.')
end
timedim = find(strcmp({GIZ.DATA{s.idat}.dims.name},'time'));
chandim = find(strcmp({GIZ.DATA{s.idat}.dims.name},'channels'));
chanlocs = GIZ.DATA{s.idat}.dims(chandim).etc;
otherdims = setxor(1:numel(GIZ.DATA{s.idat}.dims),[timedim chandim]);
timevec = GIZ.DATA{s.idat}.dims(timedim).range;

for i= 1:numel(s.times)
    tpts(i) = timepts(s.times(i),timevec);
end

data = permute(data,[chandim,timedim,otherdims]);
data = mean(data(:,:,:),3);
toplot = data(:,tpts);

cl = max(abs(toplot(:)));

[r c] = num2rowcol(numel(tpts));
for i_t = 1:numel(tpts)
    subplot(r,c,i_t)
    
    topoplot(toplot(:,i_t),chanlocs,'maplimits',[-cl cl]);
    title([num2str(s.times(i_t)) GIZ.DATA{s.idat}.dims(timedim).unit ])
end
    
    figtitle(tit)


