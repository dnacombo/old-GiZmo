function GIZ = giz_regroup(GIZ,togroup,what)

% GIZ = giz_model_X(GIZ, togroup,what)
% group results from 1st level models to prepare 2d level model
% 
% inputs:
%       togroup: models to gather data from
%       what: what results field to treat as data for 2s level

try 
    GIZ.model(togroup);
catch
    error('Models don''t all exist')
end
defifnotexist('what','TStats');

newDATA.urfname = '';
newDATA.ursetname = '';
newDATA.DAT = [];
newDATA.unit = what;
urdims = GIZ.DATA{GIZ.model(1).Y.idat}.dims;
urdims(GIZ.model(1).Y.dimsm) = [];
for i_g = togroup
    newDATA.dims = GIZ.DATA{GIZ.model(i_g).Y.idat}.dims;
    newDATA.dims(GIZ.model(i_g).Y.dimsm) = [];
    if not(isequal(newDATA.dims,urdims))
        error('Should have same dimensions across group');
    end
    m = GIZ.model(i_g);
    dimsm = m.Y.dimsm;
    d = m.(what);
    newDATA.DAT = cat(dimsm,newDATA.DAT,d);
    newDATA.event = [];
    for i_ev = 1:size(d,dimsm)
        goodfieldname = strrep(m.info.(what).names{i_ev},'GiZframe$','');
        goodfieldname = regexprep(goodfieldname,'[^\w]','');
        newDATA.event(end+1).(goodfieldname) = 1;
    end
    newDATA.eventdim = dimsm;
end
fs = fieldnames(newDATA.event);
for i = 1:numel(fs)
    newDATA.event.(fs{i})(emptycells({newDATA.event.(fs{i})})) = 0;
end

GIZ = giz_adddata(GIZ,newDATA);



