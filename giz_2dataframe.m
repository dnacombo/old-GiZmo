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

% first see if Y is to be split modeled repeatedly with same X
Ysplit = ~isempty([m.Y.dimsplit]);

% Our rationale here is that we may need (if Ysplit) to estimate many
% times a model with same predictors.
% if Ysplit, then Y is a matrix with size(D.DAT,dimsm) rows and we will
% estimate the model as many times as there are columns.
% if ~Ysplit, then we put data in the X and will write it in the
% dataframe. Model estimation will run in one step.
s = size(D.DAT);
if Ysplit
    % if we split, then we need to plan the tosplit variable 
    % to have size of the tosplit data
    dimsm = m.Y.dimsm;
    dimsplit = m.Y.dimsplit;
    % data as Y
    if not(isempty(m.Y.transform))
        switch class(m.Y.transform)
            case 'function_handle'
                D.DAT = m.Y.transform(D.DAT);
            case 'char'
                D.DAT = eval([m.Y.transform '(' D.DAT ');']);
        end
        D.DAT = reshape(D.DAT,s);% just in case we lost size in the transformation
    end
    Y = reshape(permute(D.DAT,[dimsm dimsplit]),size(D.DAT,dimsm),[]);
else
    % we're pushing a onedimentional event into X.
    % X(:,1) contains that data
    X{1} = m.Y.event;
end
% now add each predictor
for i_X = 1:numel(m.X)
    X{~Ysplit+i_X}= m.X(i_X).event;
end
for i_t = find(~emptycells({m.X.transform}))
    if ischar(e(1).(m.X(i_t).event))
        disp({e.(m.X(i_t).event)})
        error('Cannot normalize this...')
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

% create a dataframe for X (and Y if not Ysplit) with as many rows as
% there are events.
frame = struct2table(e,1,X);

if exist('Y','var')
    % and a numeric variable dat with the tosplit data.
    % later we'll need to pass information to runmodel so that it knows what
    % it is supposed to split and what not.
    dat = Y;
else
    dat = [];
end

if nargout == 0
    clear dat frame
end

