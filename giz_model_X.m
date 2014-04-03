function GIZ = giz_model_X(GIZ,varargin)

% GIZ = giz_model_X(GIZ, 'key', value)
% add predictors in the current model
% 
% input key value pairs:
%       'event', cell array of strings pointing to event names in the
%               DATA{idat}.event structure. Can add several predictors of
%               the same type (see below) at once
%               if event string starts with '-', the predictor is removed.
%
%       'type', string describing effect type: Fixed ('fix') or random
%               ('rand'). rand effects are hierarchical. They apply to
%               certain fixed effects or just to the intercept of the model
%               if no fixed effect is provided. 
%
%       'transform', a function handle (or a cell array of handles)
%               specifiing if and how a given predictor should be
%               transformed (zscore? log?...). 
%       
%       'isfact' is a vector of logical values that specifies if a given
%               predictor should be treated as a factor.
%
%

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end
type = [];transform = [];
setdefvarargin(varargin,'event',[],'type','fix','transform',{[]},'isfact',[]);
if isempty(event)
    error('specify at least one predictor')
end
if ischar(event)
    event = {event};
end
defifnotexist('isfact',~strcmp(event,'1'));
if any(strcmp(class(transform),{'function_handle' 'char'}))
    transform = {transform};
end
if numel(transform) == 1 && numel(event) > 1
    transform = repmat(transform,numel(event),1);
end

%%%% delete '-'events from the model
todel = strncmp('-',event,1);
for i = find(todel);
    tmp = strcmp({GIZ.model(GIZ.imod).X.event},event{i}(2:end));
    if sum(tmp)
        GIZ.model(GIZ.imod).X(tmp) = [];
        disp(['Removing predictor ' strrep(event{i},'-','') ])
    end
end
event(todel) = [];
isfact(todel) = [];
%%%%%

ix = size(vertcat(GIZ.model(GIZ.imod).X.event),1);
switch type
    case 'fix'
        % then add predictor
        for i_c = 1:numel(event) % could add several predictors of the same type at once
            if not(isfield(GIZ.DATA{GIZ.idat}.event,event{i_c})) && ~strcmp(event{i_c},'1')
                error(['No event named ' event{i_c} ' in the data'])
            elseif any(strcmp({GIZ.model(GIZ.imod).X.event},event{i_c}))
                disp(['Event named ' event{i_c} ' already in the model'])
            else
                disp(['Adding fixed effect predictor ' event{i_c} fastif(isfact(i_c),' as a factor','')])
                GIZ.model(GIZ.imod).X(i_c + ix).event = event{i_c};
                GIZ.model(GIZ.imod).X(i_c + ix).effect = 'fix';
                GIZ.model(GIZ.imod).X(i_c + ix).transform = transform{i_c};
                GIZ.model(GIZ.imod).X(i_c + ix).isfact = isfact(i_c);
            end
        end
    case 'rand'
        % this should point to an event, that will be used to split the
        % data, and should also point to some of the fix
        ifix = strcmp('fix',{GIZ.model(GIZ.imod).X.effect});
        if all(not(ifix))
            error('First specify fixed effects')
        end
        grouper = event{1}; % grouping variable
        grouped = event{2}; % fixed effects to group
        % (lmer will compute one coefficient per group for each of these
        % grouped events)
        if not(isfield(GIZ.DATA{GIZ.idat}.event,grouper))
            error(['No event named ' grouper ' in the data'])
        else
            gpd = regexprep(grouped,'^1$','Intercept');
            disp(['Adding groupping predictor ' grouper ' for ' sprintf('%s ',gpd{:}) ])
        end
        GIZ.model(GIZ.imod).X(ix+1).event = grouper;
        GIZ.model(GIZ.imod).X(ix+1).effect = 'rand';
        GIZ.model(GIZ.imod).X(ix+1).isfact = isfact(1);
        GIZ.model(GIZ.imod).X(ix+1).grouped = grouped;
    otherwise
        error('Predictor type not implemented')
end

GIZ.model(GIZ.imod).type = fastif(any(strcmp({GIZ.model(GIZ.imod).X.effect},'rand')),'lmer','glm');

