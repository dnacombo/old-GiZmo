% EEG = pop_loadset('Y:\Osz_04\Max\AutorejICA\AP2S005_Redo_viscor_ica.set')
% EEG = pop_loadset('/DATAtest/APP2_S005_viscor_sacrej_icacor.set');


tomod = permute(EEG.data,[3 1 2]);

EEG = pop_selectevent(EEG,'type',[111:143],'deleteevents','on');
frame = EEG.event;
fs = fieldnames(frame);
fs2del = {'StimExc','StimUnc','SDT'};
todel = 0;
for i = 1:numel(fs2del)
    todel = todel|strcmp(fs,fs2del{i});
end
fs(todel) = [];
frame2mod = rmfield(frame,fs);


%% all we need to have is:
% - a N dimensional array with some data
% - a model frame (i.e. a text table with a number of predictors as columns
%   and values as rows)
% - a formula of the type '~ Pred1 + Pred2 + Pred1:Pred2'
%
% First dimension of the data is described in the frame.


res = gizmo(tomod,'frame',frame2mod,'formula','~ StimExc + StimUnc + SDT','Rargs',struct('nblocks',1000));










