function GIZ = giz_addmodel(GIZ)

% GIZ = giz_addmodel(GIZ)
% add an empty model to GIZ structure
% models point to data and events

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end


GIZ.model(end+1).name = '';
GIZ.imod = numel(GIZ.model);

GIZ.model(GIZ.imod).type = '';

GIZ.model(GIZ.imod).family = '';% distribution family of data

GIZ.model(GIZ.imod).Y.idat = [];% pointers to DATA indices
GIZ.model(GIZ.imod).Y.event = '';% event field to be used

GIZ.model(GIZ.imod).Y.dimsm = [];% pointers to modeled dimension of data
GIZ.model(GIZ.imod).Y.dimsplit = [];% pointers to dimensions of data that 
%                                       will be split processed in turn

GIZ.model(GIZ.imod).X.idat = [];% pointer to data index
GIZ.model(GIZ.imod).X.event = '';% event name of the predictor 
GIZ.model(GIZ.imod).X.effect = '';% 'fix' or 'rand'
GIZ.model(GIZ.imod).X.isfact = [];% true if it's a factor


