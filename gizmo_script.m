EEG = pop_loadset('Y:\Osz_04\Max\AutorejICA\AP2S005_Redo_viscor_ica.set')

tomod = permute(EEG.data,[3 1 2]);

EEG = pop_selectevent(EEG,'type',[128:2:141],'deleteevents','on');
frame = EEG.event;
fs = fieldnames(frame);
fs(strcmp(fs,'Luminance')) = [];
frame2mod = rmfield(frame,fs);

res = gizmo(tomod,'frame',frame2mod,'formula','~ Luminance','Rargs',struct('nblocks',1000));










