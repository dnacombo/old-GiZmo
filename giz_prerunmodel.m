function [GIZ,ok] = giz_prerunmodel(GIZ,imod)

% [GIZ] = giz_prerunmodel(GIZ)
% prepare model data files (frame and dat) on disk.
% later to be loaded in R
if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end
defifnotexist('imod',GIZ.imod)
for imod = imod
    GIZ.imod = imod;
    [dat, frame] = giz_2dataframe(GIZ);
    
    disp('Writing dataframe.')
    ok = write_table(fullfile(GIZ.wd,[GIZ.model(GIZ.imod).name '_frame.txt']),frame);
    
    if not(isempty(dat))
        if iscellstr(dat)
            ok = write_table([GIZ.model(GIZ.imod).name '_dat.dat'],dat(:));
        else
            disp(['Writing data. (' num2str(numel(dat)*4*fastif(isa(dat,'single'),1,2),'%.3g') ' bytes)'])
            fid = fopen(fullfile(GIZ.wd,[GIZ.model(GIZ.imod).name '_dat.dat']),'w','ieee-le');
            if fid == -1
                error('Cannot write file. Check permissions and space.')
            end
            count = fwrite(fid,dat,'single');
            fclose(fid);
            if count ~= numel(dat)
                error('Error writing data to file... (Not enough space?)');
            else ok = 1;
            end
        end
    end
end
