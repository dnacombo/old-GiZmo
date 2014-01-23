function [dat frame] = giz_2dataframe(GIZ)

% [dat frame] = giz_2dataframe(GIZ)
% create frame variable (cellarray of strings to be printed as text)
% and (if needed) a data file corresponding to current model in GIZ

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

GIZ = giz_check_XY(GIZ);

% need to detect if we're going to replicate Y
% if we're replicating dimensions of Y, we extract one dataframe with
% predictors and replicate the same model n times (with n = ncol(Y))

m = GIZ.model(GIZ.imod);
D = GIZ.DATA{m.idat};
e = D.event;

% first see if Y is to be split modeled repeatedly with same X
issplit = ~isempty([m.Y.dimsplit]);

s = size(D.DAT);
if issplit > 0 % if we will, then we need to plan the tosplit variable 
    % to have size of the tosplit data
    dimsm = m.Y.dimsm;
    dimsplit = m.Y.dimsplit;
    % data as Y, tosplit(:,1) contains the data.
    Y = reshape(permute(D.DAT,[dimsm dimsplit]),size(D.DAT,dimsm),[]);
else % then we're pushing a onedimentional event as Y.
    % X(:,1) contains that data
    X{1} = m.Y.event;
end
% now for each predictor
for i_X = 1:numel(m.X)
    X{~issplit+i_X}= m.X(i_X).event;
end

% now we'll create a dataframe of X rows
frame = struct2table(e,1,X);

% and a numeric variable dat with the tosplit data.
% later we'll need to pass information to runmodel so that it knows what
% it is supposed to split and what not.

if exist('Y','var')
    dat = Y;
end

if nargout == 0
    clear dat
end

