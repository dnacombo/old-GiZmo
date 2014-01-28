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
%       'colorbar': true of false, whether to plot a colorbar next to the
%                   last topo
%       'maplimits':'absmax'   -> scale map colors to +/- the absolute-max (makes green 0); 
%                   'maxmin'   -> scale colors to the data range (makes green mid-range); 
%                   [lo.hi]    -> use user-definined lo/hi limits
%                   {default: 'absmax'}

defifnotexist('GIZ',evalin('caller','GIZ'));

defs.what = 'model';
defs.coef = 1;
defs.times = [0 100 200];
defs.idat = GIZ.idat;
defs.imod = GIZ.imod;
defs.colorbar = 1;
defs.maplimits = 'absmax';
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

if any(s.times < timevec(1)) || any(s.times > timevec(end))
    error('Time out of range')
end
for i= 1:numel(s.times)
    tpts(i) = timepts(s.times(i),timevec);
end

data = permute(data,[chandim,timedim,otherdims]);
data = mean(data(:,:,:),3);
toplot = data(:,tpts);

if isstr(s.maplimits)
    if strcmp(s.maplimits,'absmax')
        amax = max(abs(toplot(:)));
        amin = -amax;
    elseif strcmp(s.maplimits,'maxmin') | strcmp(s.maplimits,'minmax')
        amin = min(toplot(:));
        amax = max(toplot(:));
    else
        error('unknown ''s.maplimits'' value.');
    end
elseif length(s.maplimits) == 2
    amin = s.maplimits(1);
    amax = s.maplimits(2);
else
    error('unknown ''s.maplimits'' value');
end
s.maplimits = [amin amax];

[r c] = num2rowcol(numel(tpts));
for i_t = 1:numel(tpts)
    subplot(r,c,i_t)
    cla
    topoplot(toplot(:,i_t),chanlocs,'maplimits',s.maplimits);
    title([num2str(s.times(i_t)) GIZ.DATA{s.idat}.dims(timedim).unit ])
end

if not(isempty(s.colorbar))
    if numel(tpts) == 1
        if ~isstr(s.maplimits)
            ColorbarHandle = cbar(0,0,[s.maplimits(1) s.maplimits(2)]);
        else
            ColorbarHandle = cbar(0,0,get(gca, 'clim'));
        end;
        pos = get(ColorbarHandle,'position');  % move left & shrink to match head size
        set(ColorbarHandle,'position',[pos(1)-.05 pos(2)+0.13 pos(3)*0.7 pos(4)-0.26]);
    elseif ~isstr(s.maplimits)
         cbar('vert',0,[s.maplimits(1) s.maplimits(2)]);
    else cbar('vert',0,get(gca, 'clim'));
    end
%     if ~typeplot    % Draw '+' and '-' instead of numbers for colorbar tick labels
%         tmp = get(gca, 'ytick');
%         set(gca, 'ytickmode', 'manual', 'yticklabelmode', 'manual', 'ytick', [tmp(1) tmp(end)], 'yticklabel', { '-' '+' });
%     end
end
figtitle(tit,'fontsize',14)


