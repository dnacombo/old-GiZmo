function [dat frame] = giz_2dataframe(GIZ)

% [dat frame] = giz_2dataframe(GIZ)
% create frame variable (cellarray of strings to be printed as text)
% corresponding to current model in GIZ

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

GIZ = giz_check_XY(GIZ);

% need to detect what we're going to replicate: X or Y
% if we're replicating dimensions of Y, we extract one dataframe with
% predictors and replicate the same model n times (with n = ncol(Y))

% if we're replicating dimensions of one of the X, the dataframe will
% contain the Y, and we'll repeat the model with one predictor changing
% along repetitions.

m = GIZ.model(GIZ.imod);
D = GIZ.DATA{m.Y.idat};
e = D.event;

% first see if Y is to be split modeled repeatedly with same X
Y2split = ~isempty([m.Y.dimsplit]);
X2split = ~emptycells({m.X.dimsplit});

% will we split at all?
issplit = sum([Y2split X2split]);
if issplit == numel([Y2split X2split])
    % this would mean we're splitting all Y and Xs...
    error('This should not happen')
end

nosplit = cell(1,sum(~[Y2split X2split]));
s = size(D.DAT);
if issplit > 0 % if we will, then we need to plan the tosplit variable 
    % to have size of the tosplit data
    dimsm = m.(fastif(Y2split,'Y','X')).dimsm;
    dimsplit = [m.(fastif(Y2split,'Y','X')).dimsplit];
    tosplit = NaN(numel(D.event),prod(s(dimsplit)),sum([Y2split X2split]),'single');
end
if Y2split % if we need to split Y then we're pushing some multidimensional 
    % data as Y, tosplit(:,1) contains the data.
    if isempty(m.Y.event)% then it's data
        % first column of tosplit contains the data
        tosplit(:,:,1) = reshape(permute(D.DAT,[dimsm dimsplit]),size(D.DAT,dimsm),[]);
    else% then it's an event
        % we don't deal with that for the moment
        error('events as Y are not split (you should never get this error)')
    end
else % then we're pushing a onedimentional event as Y.
    % nosplit(:,1) contains that data
    nosplit{1} = m.Y.event;
end
% now for each predictor
for i_X = 1:numel(m.X)
    if X2split(i_X)% is it split?
        if isempty(m.X(i_X).event)% then it's data
            % and goes into tosplit(:,i_X)
            tosplit(:,:,sum(Y2split)+sum(X2split(1:i_X))) = reshape(permute(D.DAT,[dimsm dimsplit]),size(D.DAT,dimsm),[]);
        else% event data isn't split, for now at least
            error('inconsistency in predictor specification')
        end
    else% if it's not split, then it goes into nosplit(:,i_X)
        nosplit{sum(~Y2split)+i_X}= m.X(i_X).event;
    end
end

% now we'll create a dataframe of nosplit rows
frame = struct2table(e,1,nosplit);
% if there's no Y in that table, we add a first column with dummy data to
% replace
% if Y2split
%     frame = [repmat({'YYY'},size(frame,1),1) frame];
% end
% for i_X = 1:sum(X2split)
%     frame = [frame repmat({['XXX' num2str(i_X)]},size(frame,1),1)];
% end

% and a numeric variable dat with the tosplit data.
% later we'll need to pass information to runmodel so that it knows what
% it is supposed to split and what not.

if exist('tosplit','var')
    dat = tosplit;
end

if nargout == 0
    clear dat
end

