function GIZ = giz_model_Y(GIZ,idat, varargin)

% GIZ = giz_model_Y(GIZ,idat)
% choose data to work with for current model
%
% if idat is numeric, then it's just pointing to a given DATA structure
%
% if idat is a cell, it should have 2 elements, one pointing to a DATA
% structure, the second (a string) pointing to an event of that DATA

setdefvarargin(varargin,'transform',[]);

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

if isempty(GIZ.imod) || GIZ.imod == 0
    GIZ = giz_emptymodel(GIZ);
end
% clear eventual results
GIZ = giz_clearmodel(GIZ);
if isnumeric(idat)
    disp(['Adding Y = DATA{' num2str(idat) '}'])
    % assume we're pointing to DATA
    GIZ = giz_model_idat(GIZ,idat);
    GIZ.model(GIZ.imod).Y.event = '';
    
    % assume we're pointing to normal data (but if power, it may be
    % lognormal?)
    GIZ.model(GIZ.imod).Y.family = 'gaussian';
    GIZ.model(GIZ.imod).Y.normalize = transform;
    
    GIZ.model(GIZ.imod).Y.dimsm = GIZ.DATA{GIZ.model(GIZ.imod).Y.idat}.eventdim;
    % data is 3D and we will model 3rd dimension. We just repeat the same
    % model for the 2 other dimensions
    GIZ.model(GIZ.imod).Y.dimsplit = setxor(1:ndims(GIZ.DATA{GIZ.model(GIZ.imod).Y.idat}.DAT),GIZ.model(GIZ.imod).Y.dimsm);
elseif ischar(idat)
    % assume we're pointing to an event
    event = idat;
    disp(['Adding Y = ' event])
    GIZ = giz_model_idat(GIZ,GIZ.idat);
    clear idat
    
    GIZ.model(GIZ.imod).Y.event = event;
    
    % quick test to find distribution family of Y
    test = [GIZ.DATA{GIZ.model(GIZ.imod).Y.idat}.event.(event)];
    test = test(1:min(numel(test),1000));
    switch numel(unique(test))
        case 2
            GIZ.model(GIZ.imod).Y.family = 'binomial';
        otherwise
            GIZ.model(GIZ.imod).Y.family = 'gaussian';
    end
    % assume we're pointing to just the dimension that will be modeled.
    GIZ.model(GIZ.imod).Y.dimsm = GIZ.DATA{GIZ.model(GIZ.imod).Y.idat}.eventdim;
    GIZ.model(GIZ.imod).Y.dimsplit = [];
else
    error('when defining model data')
end

