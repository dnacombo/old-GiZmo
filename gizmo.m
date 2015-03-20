function res = gizmo(dat,varargin)

% res = gizmo(dat,...)
%
% Writes dat as a binary file to disk
% 
% optional name, value pairs
%   'frame'     = structure to write as data.frame for model.
%   'formula'   = formula string of the model
%   'Rfun'      = R function to use for modeling
%   'doRun'     = boolean whether to run the model in R or not
%
%


def = struct('fbasename','gizmo',...
    'frame',struct('one',mat2cells(ones(size(dat,1),1))),...
    'formula','~ one',...
    'Rfun','gizglm',...
    'doRun',0);

cfg = setdef(vararg2struct(varargin),def);
defRargs = struct('Rargs',struct(...
    'formula', cfg.formula, ...
    'basename', ['"' cfg.fbasename '"']));
cfg = setdef(cfg,defRargs);
cfg.Rargs = struct2vararg(cfg.Rargs);

% first write data to disk
fid = fopen([cfg.fbasename '.dat'],'w','ieee-le');
if fid == -1
    error('Cannot write file. Check permissions and space.')
end
count = fwrite(fid,dat,'single');
fclose(fid);
if count ~= numel(dat)
    error('Error writing data to file');
else wdatok = 1;
end

% then write frame to txt
wfrok = write_table([cfg.fbasename '.df'],struct2table(cfg.frame));

fid = fopen([cfg.fbasename '.R'],'wt');
str = 'source("gizfuns.R")';
fprintf(fid,'%s\n',str);

str = [cfg.Rfun '( '];
for i = 1:2:numel(cfg.Rargs)
    if ischar(cfg.Rargs{i+1})
        str = [str cfg.Rargs{i} ' = ' cfg.Rargs{i+1}];
    else
        str = [str cfg.Rargs{i} ' = ' num2str(cfg.Rargs{i+1})];
    end
    if i+1 == numel(cfg.Rargs)
        str(end+1) = ')';
    else
        str(end+1:end+2) =  ', ';
    end
end
fprintf(fid,'%s\n',str);
fclose(fid);

fid = fopen('Runscript.bat','wt');
str = ['R CMD BATCH ' [cfg.fbasename '.R']];
fprintf(fid,'%s\n',str);
fclose(fid);

delete([cfg.fbasename '_*.dat'])

if isunix
    !chmod +x Runscript.bat
end

!Runscript.bat

res = giz_readfiles(cfg.fbasename,size(dat));

return


function m = mat2cells(c)

str = 'mat2cell(c,';
for i = 1:ndims(c)
    str = [str 'ones(size(c,' num2str(i) '),1),'];
end
str(end) = ')';
m = eval(str);

function txt = struct2table(T,header,fields,sname)

% txt = struct2table(T,header,fields,sname)
% Turn fields fields of structure T into a cell array "txt".
% If header is true, a first header line is added with field names. If
% header is a cell array of strings, these strings are used as headers
% (length(header) must be == length(fields))
% If provided, sname is a string that will be added as a first column to
% each row of txt.

% if nargin == 0
%     T = evalin('caller','T');
%     fields = {'RefDur' 'Freq' 'RT' 'RealT' 'FB'};
% end
if not(exist('fields','var'))
    fields = fieldnames(T);
end
if not(exist('header','var'))
    header = true;
end
if iscellstr(header)
    headerline = header;
    header = true;
else
    headerline = fields;
end
if not(numel(headerline) == numel(fields))
    error('Number of columns inconsistency, check input');
end
gotsname = exist('sname','var');
txt = cell(numel(T)+header,numel(fields)+gotsname);
if header
    if gotsname
        txt(1,:) = {'suj' headerline{:}};
    else
        txt(1,:) = {headerline{:}};
    end
end

for itri = 1:numel(T)
    if gotsname
        txt{itri+header,1} = sname;
    end
    for i_f = 1:numel(fields)
        txt{itri+header,i_f+gotsname} = T(itri).(fields{i_f});
    end
end




