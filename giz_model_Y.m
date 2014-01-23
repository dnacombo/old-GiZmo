function GIZ = giz_model_Y(GIZ,idat)

% GIZ = giz_model_Y(GIZ,idat)
% choose data to work with for current model
%
% if idat is numeric, then it's just pointing to a given DATA structure
%
% if idat is a cell, it should have 2 elements, one pointing to a DATA
% structure, the second (a string) pointing to an event of that DATA

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

% clear eventual results
GIZ = giz_clearmodel(GIZ);

if isnumeric(idat)
    % assume we're pointing to DATA
    GIZ = giz_model_idat(GIZ,idat);
    GIZ.model(GIZ.imod).Y.event = '';
    
    % assume we're pointing to continuous data
    GIZ.model(GIZ.imod).family = 'gaussian';
    
    GIZ.model(GIZ.imod).Y.dimsm = GIZ.DATA{GIZ.model(GIZ.imod).idat}.eventdim;
    % data is 3D and we will model 3rd dimension. We just repeat the same
    % model for the 2 other dimensions
    GIZ.model(GIZ.imod).Y.dimsplit = setxor(1:ndims(GIZ.DATA{GIZ.model(GIZ.imod).idat}.DAT),GIZ.model(GIZ.imod).Y.dimsm);
elseif iscell(idat)
    % assume we're pointing to an event
    event = idat{2};
    idat = idat{1};
    
    GIZ = giz_model_idat(GIZ,idat);
    GIZ.model(GIZ.imod).Y.event = event;
    
    % test to find distribution family of Y
    test = [GIZ.DATA{GIZ.model(GIZ.imod).idat}.event.(event)];
    test = test(1:min(numel(test),1000));
    switch numel(unique(test))
        case 2
            GIZ.model(GIZ.imod).family = 'binomial';
        otherwise
            GIZ.model(GIZ.imod).family = 'gaussian';
    end
    % assume we're pointing to just the dimension that will be modeled.
    GIZ.model(GIZ.imod).Y.dimsm = GIZ.DATA{GIZ.model(GIZ.imod).idat}.eventdim;
    GIZ.model(GIZ.imod).Y.dimsplit = [];
else
    error('when defining model data')
end

