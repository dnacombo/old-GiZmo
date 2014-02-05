function [GIZ] = giz_readmodel(GIZ,imod)

% [GIZ] = giz_readmodel(GIZ,imod)
% read run model into memory.

% first check presence of results files for the current model
defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('imod',GIZ.imod);
for imod = imod
    m = GIZ.model(imod);
    shouldbehere = {'.R' '.Rout' '_coefs.dat' '_resids.dat'};
    for i = 1:numel(shouldbehere)
        f = dir([m.name shouldbehere{i}]);
        if isempty(f)
            error(['Missing ' m.name shouldbehere{i} '. Make sure you''ve run model estimation.']);
        end
    end
    dimsm = m.Y.dimsm;
    dimsplit = m.Y.dimsplit;
    s = size(GIZ.DATA{m.idat}.DAT);
    f = dir([m.name '_coefs.dat']);
    coefss = [s(dimsplit)];
    ncoefs = f.bytes / (4*prod(coefss));
    coefss = [ncoefs coefss];
    disp('Reading coefficients')
    GIZ.model(imod).coefficients = ipermute(reshape(loadbin([m.name '_coefs.dat']),coefss),[dimsm dimsplit]);
    disp('Reading residuals')
    GIZ.model(imod).residuals = ipermute(reshape(loadbin([m.name '_resids.dat']),s([dimsm dimsplit])),[dimsm dimsplit]);
    disp('Reading info')
    GIZ.model(imod).info = load([m.name '_info.mat']);
end

function d = loadbin(fn)

fid = fopen(fn,'rb','l');
d = fread(fid,Inf,'single=>single');
fclose(fid);

