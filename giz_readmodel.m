function [GIZ] = giz_readmodel(GIZ)

% first check presence of results files for the current model
if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

m = GIZ.model(GIZ.imod);
shouldbehere = {'.R' '.Rout' '_coefs.dat' '_resids.dat'};
for i = 1:numel(shouldbehere)
    f = dir([m.name shouldbehere{i}]);
    if isempty(f)
        error(['Missing ' m.name shouldbehere{i} '. Make sure you''ve run model estimation.']);
    end
end
GIZ.model(GIZ.imod).coefficients = loadbin([m.name '_coefs.mat']);
GIZ.model(GIZ.imod).residuals = loadbin([m.name '_resids.mat']);

function d = loadbin(fn)

fid = fopen(fn,'rb','l');
d = fread(fid,Inf,'single');
fclose(fid);

