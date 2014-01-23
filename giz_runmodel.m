function GIZ = giz_runmodel(GIZ)

% GIZ = giz_runmodel(GIZ)
% run the current model in R
% prepare a Rscript and run it.
% data and frame should already be on disk.

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end

how_much_at_once = 1000;

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
            return
        end
    end
else
    Rpath = '';% we don't need Rpath because R runs ok.
end

m = GIZ.model(GIZ.imod);

% now need to create a R script and run it.
% first we check how we're going to play around with data in dataframe and
% outside.
Y2split = ~isempty(m.Y.dimsplit);
X2split = ~emptycells({m.X.dimsplit});
Allatonce = all([~Y2split ~X2split]);

% start script here.
txt = {
%     'require(plyr)'% plyr has some ply functions that  we may use below.
    % change to the correct directory
    ['setwd(''' strrep(GIZ.wd,'\','/') ''')']
    ''
    % read the data frame
    ['GiZframe <- read.table("' m.name '_frame.txt",header=T)']
    };
% changing frame fields to factors if needed
for i_X = 1:numel(m.X)
    if m.X(i_X).isfact
        txt = [txt; ['GiZframe$' m.X(i_X).event ' <- factor(GiZframe$' m.X(i_X).event ')']];
    end
end
if not(Allatonce)
    % setup variables that are going to be useful to know how much we read
    txt = [txt
        'nobss <- nrow(GiZframe)'
        % we're going to process blocks of how_much_at_once models at once
        ['nblocs <- ' num2str(how_much_at_once)]
        {''}
        ];
end

txt = [txt;
    {''}
    % here we create a function that we'll run either once, or in blocks
    % of nblocs untill all the data has been modeled
    ['f <- function (' fastif(Allatonce,'','Y,') 'fr) {']
    %%%%%%%%
    % display a text progress bar
    '    assign("i",i + 1,envir = .GlobalEnv)'
    '    setTxtProgressBar(pb, i)'
    %%%%%%%%
    ];

% get the R formula corresponding to the current model
formula = giz_model_formula(GIZ);

switch m.type
    case 'glm'
        if any(X2split)
            % call glm with formula and family
            txt = [txt; ['    glm(' formula ', family= ' m.family ')']];
        else
            txt = [txt; ['    glm.fit(x=x,y=Y, family= ' m.family '() )']];
        end
    case 'lmer'
        error('todo')
        line = 'lmer(';
end
txt = [txt;'}';{''}];

%%%%%%%% end of estimation function
%%% here we prepare the design matrix if possible
if ~any(X2split)
    txt = [txt; 
        'fr <- GiZframe'
        'x <- model.matrix(' regexprep(formula,'.*(~.*)','$1') ')'];
end

%%%%%%%%
% display a text progress bar
datf = dir(fullfile(GIZ.wd,[m.name '_dat.dat']));
txt = [txt;'pb <- txtProgressBar(min=0,max=ceiling(' num2str(datf.bytes/4) '/nobss),style = 3)'];
txt = [txt;'i <- 0';];
%%%%%%%%

% now actually run the model
if Allatonce
    % only once if all the data fits into the data.frame
    txt = [txt; 'res <- f(GiZframe)'];
    switch m.type
        case 'glm'
            txt = [txt;
                'coefs = coef(res)'
                'residuals = resid(res)'
                checkdel([m.name '_coefs.dat']);
                checkdel([m.name '_resids.dat']);
                writebin([m.name '_coefs.dat'],'coefs')
                writebin([m.name '_resids.dat'],'residuals')
                ];
        case 'lmer'
            error('todo')
            line = 'lmer(';
    end
else % repeatedly (in a while loop) if we need to scan a bigger data file
    % first need to delete older files
    switch m.type
        case 'glm'
            txt = [txt;
                {''}
                checkdel([m.name '_coefs.dat']);
                checkdel([m.name '_resids.dat']);];
        case 'lmer'
            error
    end
    
    txt = [txt;
        {''}
        ['fid <- file(description = "' m.name '_dat.dat",open="rb" )']
        'while (T) {'
        ['    dat <- readBin(con=fid,what="numeric",n=nblocs*nobss,size=4,endian="little")']
        '    if (length(dat) == 0) break '
        '    dim(dat) <- c(nobss,length(dat)/nobss)'
        '    res <- apply(dat,2,f,fr=GiZframe)'
        ];
    switch m.type
        case 'glm'
%             % we need to permute dimensins before writing to match original
%             % dimensions.
%             % in giz_2dataframe, we've permuted [dimsm dimsplit]
%             % here we'll reverse permute...
%             
%             dimsm = m.(fastif(Y2split,'Y','X')).dimsm;
%             dimsplit = [m.(fastif(Y2split,'Y','X')).dimsplit];
%             order = [dimsm dimsplit];
%             inverseorder(order) = 1:numel(order);
%             inverseorderstr = sprintf('c(%g,%g,%g)',inverseorder);
            txt = [txt;
                {''}
                '    coefs = sapply(res,coef)'
                '    residuals = sapply(res,resid)'
                writebin([m.name '_coefs.dat'],'coefs');%['aperm(coefs,' inverseorderstr ')'])
                writebin([m.name '_resids.dat'],'residuals');%['aperm(residuals,' inverseorderstr ')'])
                ];
        case 'lmer'
            error('todo')
    end
    txt = [txt;
        '}'
        'close(fid)'
        ];
end

fid = fopen(fullfile(GIZ.wd,[m.name '.R']),'wt');
for i = 1:numel(txt)
    fprintf(fid,'%s\n',txt{i});
end
fclose(fid);
fid = fopen(fullfile(GIZ.wd,'Runscript'),'wt');
if not(isempty(Rpath))
    str = ['set PATH=' Rpath ';%%PATH%%'];
    fprintf(fid,'%s\n',str);
end
str = ['R CMD BATCH ' [m.name '.R']];
fprintf(fid,'%s\n',str);
fclose(fid);
if isunix
    !chmod +x Runscript
end
!./Runscript
delete('Runscript')

function txt = writebin(fname,datvar)

txt = {
    ['    fud <- file(description = "' fname '",open="ab" )']
    ['    ok <- writeBin(object=as.vector(' datvar '),con=fud,size=4,endian="little")']
    '    close(fud)'
    };


function txt = checkdel(fname)

txt = {
    ['if (file.exists("' fname '")) file.remove("' fname '")']
    };

