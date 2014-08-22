function [GIZ] = giz_readmodel(GIZ,imod,readresiduals)

% [GIZ] = giz_readmodel(GIZ,imod)
% read run model into memory.
% [GIZ] = giz_readmodel(GIZ,imod,readresiduals)
% if readresiduals is true, also read the residuals of the model (can be
% quite big)... default is not to read them.

% first check presence of results files for the current model
defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('imod',GIZ.imod);
defifnotexist('readresiduals',0);

for imod = imod
    m = GIZ.model(imod);
    switch m.type
        case 'glm'
            shouldbehere = {'.R' '.Rout' '_coefs.dat' '_resids.dat'};
        case 'lmer'
            shouldbehere = {'.R' '.Rout' '_fixefs.dat' '_ranefs.dat' '_resids.dat'};
    end
    for i = 1:numel(shouldbehere)
        f = dir([GIZ.wd filesep m.name shouldbehere{i}]);
        if isempty(f)
            error(['Missing ' m.name shouldbehere{i} '. Make sure you''ve run model estimation.']);
        end
    end
    dimsm = m.Y.dimsm;
    dimsplit = m.Y.dimsplit;
    s = size(GIZ.DATA{m.Y.idat}.DAT);
    switch m.type
        case 'glm'
            f = dir([GIZ.wd filesep m.name '_coefs.dat']);
            coefss = [s(dimsplit)];
            ncoefs = f.bytes / (4*prod(coefss));
            coefss = [ncoefs coefss];
            disp('Reading coefficients')
            GIZ.model(imod).coefficients = ipermute(reshape(loadbin([GIZ.wd filesep m.name '_coefs.dat']),coefss),[dimsm dimsplit]);
            disp('Reading TStats')
            GIZ.model(imod).TStats = ipermute(reshape(loadbin([GIZ.wd filesep m.name '_TStats.dat']),coefss),[dimsm dimsplit]);
        case 'lmer'
            f = dir([GIZ.wd filesep m.name '_fixefs.dat']);
            coefss = [s(dimsplit)];
            ncoefs = f.bytes / (4*prod(coefss));
            coefss = [ncoefs coefss];
            disp('Reading fixed coefficients')
            GIZ.model(imod).fixefs = ipermute(reshape(loadbin([GIZ.wd filesep m.name '_fixefs.dat']),coefss),[dimsm dimsplit]);
            
            f = dir([GIZ.wd filesep m.name '_ranefs.dat']);
            coefss = [s(dimsplit)];
            ncoefs = f.bytes / (4*prod(coefss));
            coefss = [ncoefs coefss];
            disp('Reading random coefficients')
            GIZ.model(imod).ranefs = ipermute(reshape(loadbin([GIZ.wd filesep m.name '_ranefs.dat']),coefss),[dimsm dimsplit]);
    end
    if readresiduals
        disp('Reading residuals')
        GIZ.model(imod).residuals = ipermute(reshape(loadbin([GIZ.wd filesep m.name '_resids.dat']),s([dimsm dimsplit])),[dimsm dimsplit]);
    end
    disp('Reading info')
    GIZ.model(imod).info = load([GIZ.wd filesep m.name '_info.mat']);
end

function d = loadbin(fn)

fid = fopen(fn,'rb','l');
d = fread(fid,Inf,'single=>single');
fclose(fid);

