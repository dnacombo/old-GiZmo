function giz_save(GIZ,force)

% giz_save(GIZ,force)
% save the GIZ structure
% overwrite without prompt if force is true

if not(exist('force','var')) || isempty(force)
    force = 0;
end

if not(force)
    if exist(fullfile(GIZ.wd,'GIZ.mat'),'file')
        rep = questdlg('File exists. Overwrite?','giz_save: File Exists','No');
        switch rep
            case 'No'
                return
            case 'Cancel'
                error('Cancel save GIZ file')
        end
            
    end
end

save(fullfile(GIZ.wd,'GIZ.mat'),'GIZ');



