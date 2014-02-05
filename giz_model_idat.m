function GIZ = giz_model_idat(GIZ,idat)

% change model data pointer. Reset all Y and X specifications if events
% don't exist in new data.

if isempty(GIZ.model(GIZ.imod).idat)
%     GIZ = giz_emptymodel(GIZ,GIZ.imod,'name',GIZ.model(GIZ.imod).name);
    GIZ.model(GIZ.imod).idat = idat;
    return
end
if  idat ~= GIZ.model(GIZ.imod).idat
    currentevents = {GIZ.model(GIZ.imod).X.event GIZ.model(GIZ.imod).Y.event };
    currentevents = currentevents(~emptycells(currentevents));
    goodevents = isfield(GIZ.DATA{idat}.event,currentevents);
    if not(all(goodevents))
        disp('Clearing current predictors.')
        disp('You''re pointing to new data that does not contain these predictors.')
        disp(currentevents(~goodevents))
        GIZ = giz_emptymodel(GIZ,GIZ.imod,'name',GIZ.model(GIZ.imod).name);
    end
    GIZ.model(GIZ.imod).idat = idat;
end