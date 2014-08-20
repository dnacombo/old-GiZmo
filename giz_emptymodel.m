function GIZ = giz_emptymodel(GIZ,imod,varargin)

% GIZ = giz_emptymodel(GIZ)
% add an empty model
% We possibly add model parameters right here via varargin.
% e.g. 'name','testmodel'
%

newmod = vararg2struct(varargin,'');
defifnotexist('GIZ',evalin('caller','GIZ'));

if not(exist('imod','var')) || isempty(imod)
    imod = GIZ.imod + 1;
end
GIZ.imod = imod;
if GIZ.imod == 0 || imod == 0
    GIZ.model = [];
    GIZ.imod = 1;
    imod = 1;
end
defmod.name = ['model_' datestr(now,'dd-mmm-yyyy_HH-MM-SS')] ;
defmod.type = '';
defmod.Y.idat = [];% pointer to DATA index
defmod.Y.family = '';% distribution family of data
defmod.Y.transform = [];% handle to data transform function
defmod.Y.event = '';% event field to be used
%                                  if this stays empty, we'll use the
%                                  DATA(idat).DAT directly. 
defmod.Y.dimsm = [];% pointers to modeled dimension of data
%                                  for now this is always going to be 3
%                                  (trial dimension in eeglab)
defmod.Y.dimsplit = [];% pointers to dimensions of data that 
%                                     will be split processed in turn. This
%                                     is empty if we're pointing to events,
%                                     because we assume we can model them
%                                     at once. 
defmod.X.event = '';% event name of the predictor 
defmod.X.effect = '';% 'fix' or 'rand'
defmod.X.transform = [];% handle to a function used for 
%                         transforming values of the predictor
%                         (@zscore, @log ...)
defmod.X.isfact = [];% true if it's a factor
defmod.coefficients = [];
defmod.residuals = [];
defmod.info = [];

disp(['Creating empty model ' num2str(GIZ.imod)]);
if isempty(GIZ.model)
    GIZ.model = setdef(newmod,defmod);
else
    GIZ.model(GIZ.imod) = setdef(newmod,defmod);
end




