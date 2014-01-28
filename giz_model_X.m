function GIZ = giz_model_X(GIZ, event, type, isfact)

% GIZ = giz_model_X(GIZ, event, type, isfact)
% add predictors in the current model
%
% Event is a cell array of strings pointing to event names in the
% DATA{idat}.event structure
% if event string starts with '-', the predictor is removed.
%
% effect type can be fixed ('fix') or random ('rand').
% rand effects are hierarchical. They apply to certain fixed effects or
% just to the intercept of the model if no fixed effect is provided.
%
% isfact specifies if a given predictor should be treated as a factor.

defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('type','fix');
if isempty(event)
    error('specify at least one predictor')
end
if ischar(event)
    event = {event};
end
defifnotexist('isfact',ones(1,numel(event)));

% delete '-'events from the model
todel = strncmp('-',event,1);
for i = find(todel);
    tmp = strcmp({GIZ.model(GIZ.imod).X.event},event{i}(2:end));
    GIZ.model(GIZ.imod).X(tmp) = [];
end
event(todel) = [];
isfact(todel) = [];

switch type
    case 'fix'
        % then add predictor
        ix = numel([GIZ.model(GIZ.imod).X.event]);
        for i_c = 1:numel(event)
            GIZ.model(GIZ.imod).X(i_c + ix).event = event{i_c};
            GIZ.model(GIZ.imod).X(i_c + ix).effect = 'fix';
            GIZ.model(GIZ.imod).X(i_c + ix).isfact = isfact(i_c);
        end
    case 'rand'
        % this should point to an event, that will be used to split the
        % data, and should also point to some of the fix
        error('todo')
        if all(not(strcmp('fix',{GIZ.model(GIZ.imod).X(i_c + ix).effect})))
            error('First specify fixed effects')
        end
        
        
end

GIZ.model(GIZ.imod).type = fastif(any(strcmp({GIZ.model(GIZ.imod).X.effect},'rand')),'lmer','glm');

