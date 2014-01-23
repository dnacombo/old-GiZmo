function GIZ = giz_clearmodel(GIZ)
% GIZ = giz_clearmodel(GIZ)
% remove all previously run model estimates (useful when changing model
% parameters).



fields2remove = {'coefficients','residuals'};

if any(isfield(GIZ.model(GIZ.imod),fields2remove))
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