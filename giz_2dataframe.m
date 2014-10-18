function [dat frame] = giz_2dataframe(GIZ)

% [dat frame] = giz_2dataframe(GIZ)
% create frame variable (cellarray of strings to be printed as text)
% and (if needed) a data matrix corresponding to current model in GIZ

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

GIZ = giz_check_XY(GIZ);

% need to detect if we're going to replicate Y
% if we're replicating dimensions of Y, we extract one dataframe with
% predictors and replicate the same model n times (with n = ncol(Y))

m = GIZ.model(GIZ.imod);
D = GIZ.DATA{m.Y.idat};
e = D.event;

% we've dealt with intercept or not at another level.
m.X(strcmp({m.X.event},'1')) = [];
m.X(strcmp({m.X.event},'-1')) = [];

if not(isempty(m.Y.event))% then we're modeling an event
    s = numel(D.event);
    if ischar(D.event(1).(m.Y.event))
        D.DAT = {D.event.(m.Y.event)};
    else
        D.DAT = [D.event.(m.Y.event)];
    end
    if numel(D.DAT) ~= numel(D.event)
        error(['Empty events in GIZ(' num2str(GIZ.idat) ').' m.Y.event])
    end
else
    s = size(D.DAT);
end
% we need to plan the tosplit variable
% to have size of the tosplit data
dimsm = m.Y.dimsm;
dimsplit = m.Y.dimsplit;
if not(isempty(m.Y.transform))
    switch class(m.Y.transform)
        case 'function_handle'
            D.DAT = m.Y.transform(D.DAT);
        case 'char'
            D.DAT = eval([m.Y.transform '(' D.DAT ');']);
    end
    D.DAT = reshape(D.DAT,s);% just in case we lost size in the transformation
end
if isempty(dimsplit)
    Y = D.DAT;
else
    Y = reshape(permute(D.DAT,[dimsm dimsplit]),size(D.DAT,dimsm),[]);
end
% now add each predictor
for i_X = 1:numel(m.X)
    X{i_X}= m.X(i_X).event;
end
for i_t = find(~emptycells({m.X.transform}))
    if ischar(e(1).(m.X(i_t).event))
        disp({e.(m.X(i_t).event)})
        error('Cannot work numerically on this...')
    end
    switch class(m.X(i_t).transform)
        case 'function_handle'
            tmp = m.X(i_t).transform([e.(m.X(i_t).event)]);
        case 'char'
            tmp = eval([m.X(i_t).transform '(' [e.(m.X(i_t).event)] ');']);
    end
    for i_e = 1:numel(e)
        e(i_e).(m.X(i_t).event) = tmp(i_e);
    end
end

% create a dataframe for X with as many rows as
% there are events.
frame = struct2table(e,1,X);

% and a data variable dat with the data.
% later we'll need to pass information to runmodel so that it knows what
% it is supposed to split and what not.
if isnumeric(Y)
    dat = single(Y);
else
    dat = Y;
end

if nargout == 0
    clear dat frame
end

