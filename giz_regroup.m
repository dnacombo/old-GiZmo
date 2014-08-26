function GIZ = giz_regroup(GIZ,togroup,what)

% GIZ = giz_model_X(GIZ, togroup,what)
% group results from 1st level models to prepare 2d level model
% add groupped data to GIZ.
%
% Note: subsequently, you need to add predictors with giz_model_X
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

% create a new DATA structure with all datasets catenated in it
newDATA.urfname = '';
newDATA.ursetname = '';
newDATA.DAT = [];
newDATA.unit = what;
newDATA.event = [];
% same dimensions as grouped data
urdims = GIZ.DATA{GIZ.model(1).Y.idat}.dims;
% except for the modeled dimension
urdims(GIZ.model(1).Y.dimsm) = [];
for i_g = togroup % for each of the models to catenate
    % check that dimensions match
    newDATA.dims = GIZ.DATA{GIZ.model(i_g).Y.idat}.dims;
    newDATA.dims(GIZ.model(i_g).Y.dimsm) = [];
    if not(isequal(newDATA.dims,urdims))
        error('Should have same dimensions across group');
    end
    % take that model
    m = GIZ.model(i_g);
    dimsm = m.Y.dimsm; % will catenate on the modeled dimension
    d = m.(what);% this is the data to append
    newDATA.DAT = cat(dimsm,newDATA.DAT,d);% append along dimsm
    % create event struct
    eff = m.info.(what).names;
    for i_ef = 1:numel(eff)
        % there should be one event (effect) per element of the new data on the dimsm dimension
        goodfieldname = regexprep(eff{i_ef},'[^\w]','');
        if regexp(goodfieldname,'\d') == 1
            disp(['fieldname ' goodfieldname ' is invalid. Adding ''a'' at the beginning'])
            goodfieldname = ['a' goodfieldname];
        end
        % code these events with 0 and 1
        newDATA.event(end+1).(goodfieldname) = 1;
    end
    newDATA.eventdim = dimsm;
end
% for each field, we insert 0 events where missing above.
fs = fieldnames(newDATA.event);
for i = 1:numel(fs)
    c = emptycells({newDATA.event.(fs{i})});
    d = repmat({0},1,sum(c));
    [newDATA.event(c).(fs{i})] = d{:};
end
% we end up with dummy coded events in newDATA.

GIZ = giz_adddata(GIZ,newDATA);



