function Rpath = giz_checkR

% check that R is installed and runs.

%%% check that R is here and works. Point to it if necessary.
s = system('R --version');
if s == 127
    Rpath = getpref('GiZmo','Rpath',cd);
    while isempty(flister('R(.exe)?','dir',Rpath))
        Rpath = uigetdir(cd,'Select R directory');
        if isequal(Rpath,0)
            disp('============')
            disp('You must install R first')
            disp('============')
            Rpath = 'R must be installed';
            return
        end
    end
else
    Rpath = '';% we don't need Rpath because R runs ok.
end
