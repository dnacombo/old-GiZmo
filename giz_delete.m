function GIZ = giz_delete(GIZ,varargin)

% GIZ = giz_delete(GIZ,'model',imod)
% delete model(s) imod from GIZ structure
%
% GIZ = giz_delete(GIZ,'model',imod,'files',1)
% also delete model files if any
%
% GIZ = giz_delete(GIZ,'data',idat)
% delete DATA(s) idat
def.files = 0;
s = vararg2struct(varargin,'');
s = setdef(s,def);

% avoid bothering when deleting non existing models/data
s.model = intersect(1:numel(GIZ.model),s.model);
s.data = intersect(1:numel(GIZ.DATA),s.data);

if def.files
    if isfield(s,'model')
        for i = 1:numel(s.model)
            delete([GIZ.model(i).name '*.dat'])
            delete([GIZ.model(i).name '.R'])
            delete([GIZ.model(i).name '.Rout'])
            delete([GIZ.model(i).name '_frame.txt'])
        end
    end
end            
    
if isfield(s,'model')
    GIZ.model(s.model) = [];
    if GIZ.imod > numel(GIZ.model)
        GIZ.imod = numel(GIZ.model);
    end
end

if isfield(s,'data')
    GIZ.DATA(s.data) = [];
    if GIZ.idat > numel(GIZ.DATA)
        GIZ.idat = numel(GIZ.DATA);
    end
end     




