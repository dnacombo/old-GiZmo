function GIZ = giz_model_X(GIZ, idat, type, isfact)

% GIZ = giz_model_X(GIZ, idat, type, isfact)
% add predictors in the current model
%
% if idat is numeric, then it's just pointing to a given DATA structure
%
% if idat is a cell with 2 elements, one pointing to a DATA structure, the
% second (a string) pointing to an event of that DATA
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


if isnumeric(idat)
    % we're just pointing to DATA
    if numel(idat) > 1
        error('cannot point to several data fields for predictors')
    end
    if not(exist('isfact','var')) || isempty(isfact)
        isfact = ones(1,numel(idat));
    end
    % if it's already in there, we delete it and return
    isalready = [GIZ.model(GIZ.imod).X.idat] == idat;
    isalready = isalready & emptycells({GIZ.model(GIZ.imod).X.event});
    if any(isalready)
        GIZ.model(GIZ.imod).X(isalready) = [];
    else
        % else add predictor. 
        ix = numel(GIZ.model(GIZ.imod).X);
        switch type
            case 'fix'
                GIZ.model(GIZ.imod).X(ix+1).event = [];
                GIZ.model(GIZ.imod).X(ix+1).idat = idat;
                GIZ.model(GIZ.imod).X(ix+1).effect = 'fix';
                GIZ.model(GIZ.imod).X(ix+1).isfact = 0;
                GIZ.model(GIZ.imod).X(ix+1).dimsm = 3;
                % DATA will be split.
                GIZ.model(GIZ.imod).X(ix+1).dimsplit = [1 2];
            case 'rand'
                error('todo')
        end
    end
elseif numel(idat) == 2% it's not numeric and numel is 2
    % we're pointing to (an) event(s)
    event = idat{2};
    idat = idat{1};
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
            ix = numel([GIZ.model(GIZ.imod).X.idat]);
            for i_c = 1:numel(event)
                if isempty(event{i_c})
                    GIZ = giz_model_X(GIZ,idat,type,isfact);
                    continue
                end
                GIZ.model(GIZ.imod).X(i_c + ix).event = event{i_c};
                GIZ.model(GIZ.imod).X(i_c + ix).idat = idat;
                GIZ.model(GIZ.imod).X(i_c + ix).effect = 'fix';
                GIZ.model(GIZ.imod).X(i_c + ix).isfact = isfact(i_c);
                GIZ.model(GIZ.imod).X(i_c + ix).dimsm = 3;
                % events are going to be used always identical along all
                % split dimensions of data
                GIZ.model(GIZ.imod).X(i_c + ix).dimsplit = [];
            end
        case 'rand'
            % this should point to an event, that will be used to split the
            % data, and should also point to some of the Xfix
            error('todo')
    end
else
    error('when defining model predictors')
end

GIZ.model(GIZ.imod).type = fastif(any(strcmp({GIZ.model(GIZ.imod).X.effect},'rand')),'lmer','glm');

