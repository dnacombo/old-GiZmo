function GIZ = giz_clearmodel(GIZ)
% GIZ = giz_clearmodel(GIZ)
% remove all previously run model estimates (useful when changing model
% parameters).

defifnotexist('GIZ',evalin('caller','GIZ'));


fields2remove = {'coefficients','residuals'};
for i = 1:numel(fields2remove)
    test(i) = isfield(GIZ.model(GIZ.imod),fields2remove{i}) && ~isempty(GIZ.model(GIZ.imod).(fields2remove{i}));
end

if any(test)
    [rep] = questdlg('This will clear the current model estimates. Are you sure?', 'Clearing model estimates','Yes','No','Yes');
    switch rep
        case 'No'
            error('User refuses to clear model estimates...')
    end
end
for i = 1:numel(fields2remove)
    GIZ.model(GIZ.imod).(fields2remove{i}) = [];
end

% need to also delete the files.