function [GIZ] = giz_readmodel(GIZ,imod,what,readresiduals)

% [GIZ] = giz_readmodel(GIZ,imod)
% read run model into memory.
% [GIZ] = giz_readmodel(GIZ,imod,what)
% if what is provided, it should be a string or cell array of strings
% telling which result file to read from the model. Default is fixed
% effects and Tstatistics {'fixefs','TStats'}
% [GIZ] = giz_readmodel(GIZ,imod,what,readresiduals)
% if readresiduals is true, also read the residuals of the model (can be
% quite big)... default is not to read them.

% first check presence of results files for the current model
defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('imod',GIZ.imod);
defifnotexist('readresiduals',0);
defifnotexist('what',{'fixefs','TStats'});

if ischar(what)
    what = {what};
end
for imod = imod
    m = GIZ.model(imod);
    switch m.type
        case 'glm'
            shouldbehere = {'.R' '.Rout' '_fixefs.dat' '_resids.dat'};
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
            f = dir([GIZ.wd filesep m.name '_fixefs.dat']);
            coefss = [s(dimsplit)];
            ncoefs = f.bytes / (4*prod(coefss));
            coefss = [ncoefs coefss];
            for i_what = 1:numel(what)
                disp(['Reading ' what{i_what}])
                GIZ.model(imod).(what{i_what}) = ipermute(reshape(loadbin([GIZ.wd filesep m.name '_' what{i_what} '.dat']),coefss),[dimsm dimsplit]);
            end
        case 'lmer'
            f = dir([GIZ.wd filesep m.name '_fixefs.dat']);
            coefss = [s(dimsplit)];
            ncoefs = f.bytes / (4*prod(coefss));
            coefss = [ncoefs coefss];
            for i_what = 1:numel(what)
                disp(['Reading ' what{i_what}])
                GIZ.model(imod).(what{i_what}) = ipermute(reshape(loadbin([GIZ.wd filesep m.name '_' what{i_what} '.dat']),coefss),[dimsm dimsplit]);
            end
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

