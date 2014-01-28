function giz_save(GIZ,filename,force)

% giz_save(GIZ,force)
% save the GIZ structure
% overwrite without prompt if force is true
defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('force',0);
defifnotexist(filename,'GIZ');

if not(force)
    if exist(fullfile(GIZ.wd,[filename,'.mat']),'file')
        rep = questdlg(['File ' fullfile(GIZ.wd,[filename,'.mat']) ' exists. Overwrite?'],'giz_save: File Exists','No');
        switch rep
            case 'No'
                return
            case 'Cancel'
                error('Cancel save GIZ file')
        end
            
    end
end

DAT2del = {'DAT'};
model2del = {'coefficients','residuals'};
for idat = 1:numel(GIZ.DATA)
    for i_dat = 1:numel(DAT2del)
        GIZ.DATA{idat}.(DAT2del{i_dat}) = [];
    end
end
for imod = 1:numel(GIZ.model)
    for i_mod = 1:numel(model2del)
        GIZ.model(imod).(model2del{i_mod}) = [];
    end
end

save(fullfile(GIZ.wd,[filename,'.mat']),'GIZ');



