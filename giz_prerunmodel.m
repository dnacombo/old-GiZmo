function [ok] = giz_prerunmodel(GIZ)

% [ok] = giz_prerunmodel(GIZ)
% prepare model data files (frame and dat) on disk.
% later to be loaded in R

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

[dat, frame] = giz_2dataframe(GIZ);


ok = write_table(fullfile(GIZ.wd,[GIZ.model(GIZ.imod).name '_frame.txt']),frame);

if not(isempty(dat))
    fid = fopen(fullfile(GIZ.wd,[GIZ.model(GIZ.imod).name '_dat.dat']),'w','ieee-le');
    if fid == -1
        error('Cannot write file. Check permissions and space.')
    end
    count = fwrite(fid,dat,'single');
    fclose(fid);
    if count ~= numel(dat)
        error('Error writing data to file');
    else ok = 1;
    end
    % save(fullfile(GIZ.wd,[GIZ.model(GIZ.imod).name '_dat.mat']),'dat');
end
