function GIZ = giz_model_X(GIZ, event, type, isfact)

% GIZ = giz_model_X(GIZ, event, type, isfact)
% add predictors in the current model
%
% if event is a cell array of strings pointing to event names in the
% DATA{idat}.event structure
%
% effect type can be fixed ('fix') or random ('rand').
% rand effects are hierarchical. They apply to certain fixed effects or
% just to the intercept of the model if no fixed effect is provided.
% can be added or removed (if choice points to a predictor already in the
% model, it is removed).
%
% isfact specifies if a given predictor should be treated as a factor.

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

if not(exist('type','var')) || isempty(type)
    type = 'fix';
end


% we're pointing to (an) event(s)
if not(exist('isfact','var')) || isempty(isfact)
    isfact = ones(1,numel(event));
end
if ischar(event)
    event = {event};
end
switch type
    case 'fix'
        % if it's already in there, we delete
        isalready = regexpcell({GIZ.model(GIZ.imod).X.event},event,'exact');
        delchoice = {GIZ.model(GIZ.imod).X(isalready).event};
        GIZ.model(GIZ.imod).X(isalready) = [];
        event(regexpcell(event,delchoice,'exact')) = [];
        isfact(regexpcell(event,delchoice,'exact')) = [];
        % then add predictor
        ix = numel([GIZ.model(GIZ.imod).X.event]);
        for i_c = 1:numel(event)
            GIZ.model(GIZ.imod).X(i_c + ix).event = event{i_c};
            GIZ.model(GIZ.imod).X(i_c + ix).effect = 'fix';
            GIZ.model(GIZ.imod).X(i_c + ix).isfact = isfact(i_c);
        end
    case 'rand'
        % this should point to an event, that will be used to split the
        % data, and should also point to some of the Xfix
        error('todo')
end

GIZ.model(GIZ.imod).type = fastif(any(strcmp({GIZ.model(GIZ.imod).X.effect},'rand')),'lmer','glm');

