function GIZ = giz_empty

% GIZ = giz_empty
% create an empty GIZ structure, as described below...

GIZ = struct;
GIZ.wd = cd;
% DATA structures
GIZ.DATA = {};
% format will be:
% GIZ.DATA{}.DAT = [];% data (single)
% GIZ.DATA{}.dims(1).name = '';% 'time' 'trials' 'channels'...
% GIZ.DATA{}.dims(1).range = {};% or []; channel names, time points, trial numbers...
% GIZ.DATA{}.dims(1).unit = ''; % unit of dimension (s, Hz...) if any
% GIZ.DATA{}.dims(1).etc = ;% any additional data (chanlocs...)
% GIZ.DATA{}.unit = '';% unit of data (like \{mu}V)

% GIZ.idat = 1; % index to current data
% I have to find a solution when data is in several files on disk
% I should somehow point to the file name, then, but have a way to get the
% size of the data to be able to plan reading it.
% I could simplify my life a lot if I used STUDY structures.

% events, inspired by EEGLAB

% GIZ.DATA{}.event.name = '';% event name
% GIZ.DATA{}.event.value = {};% cell array of values for that event.

% dimensions that the event applies to.
% GIZ.DATA{}.event.dims = {};
% one cell per dimension
% NaN means replicated along all indices of that dimension
% value means index in the dimension in full data that the event applies to
% several values mean the event applies at several indices of the dimension

% classical eeglab events are applied to particular indices in the time
% dimension, replicated along trial and sensor dimensions
% i.e. typical event.dims structure for an imported EEG structure could be
% {NaN 512 [1 2 4 ...]}% for an event present at sample 512 for trials 1 2 4 etc.

% model description:
GIZ.model = {};
% GIZ.model{}.type = '';% type = lm, glm, lmer...
% GIZ.model{}.Y.idat = [];% pointer to DATA or event
% GIZ.model{}.Y.event = '';% if not empty, should indicate what event to use as data
% GIZ.model{}.Y.dimsm = [];% modeled dimensions
% GIZ.model{}.Y.dimsplit = [];% replicated dimensions

% % pointers to all predictors
% GIZ.model{}.X = [];% pointers to event structure
% GIZ.model{}.Xfix = [];
% GIZ.model{}.Xfixfact = 0|1; % true if Xfix are factors
% GIZ.model{}.Xrand = [];


