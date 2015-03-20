function res = giz_readfiles(fbasename,expectedsize)

res = struct();
fs = dir([fbasename '_*.dat']);
for i = 1:numel(fs)
    field = regexp(fs(i).name,[fbasename '_(.*).dat'],'tokens');
    field = field{1}{1};
    d = loadbin(fs(i).name);
    if numel(d) == prod(expectedsize)
        res.(field) = reshape(d,expectedsize);
    else
        s = mat2cells(expectedsize(2:end));
        res.(field) = reshape(d,[],s{:});
    end
end


function d = loadbin(fn)

fid = fopen(fn,'rb','l');
d = fread(fid,Inf,'single=>single');
fclose(fid);
