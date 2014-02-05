function GIZ = giz_runmodel(GIZ,imod)

% GIZ = giz_runmodel(GIZ,imod)
% run the current model in R
% prepare a Rscript and run it.
% data and frame should already be on disk.

defifnotexist('GIZ',evalin('caller','GIZ'));
defifnotexist('imod',GIZ.imod);

cd(GIZ.wd);
how_much_at_once = 1000;

Rpath = giz_checkR;
if not(Rpath)
    error('must install R')
end
% Initialize batch
fid = fopen(fullfile(GIZ.wd,'Runscript'),'wt');
if not(isempty(Rpath))
    str = ['set PATH=' Rpath ';%%PATH%%'];
    fprintf(fid,'%s\n',str);
end
fclose(fid);

% for all the models we want to run
for imod = imod
    m = GIZ.model(imod);
    txt = {'require(R.matlab)'
        fastif(strcmp(m.type,'lmer'),'require(lme4)','')};
        
    
    % now need to create a R script and run it.
    % first we check how we're going to play around with data in dataframe and
    % outside.
    % if we're not planning to split Y, then not.
    Allatonce = isempty(m.Y.dimsplit);
    
    % start script here.
    txt = [txt;
        ['# ##### model ' m.name '#####']
        % change to the correct directory
        ['setwd(''' strrep(GIZ.wd,'\','/') ''')']
        {''}
        % read the data frame
        ['GiZframe <- read.table("' m.name '_frame.txt",header=T)']
        ];
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
        ['f <- function (' fastif(Allatonce,'','Y') ') {']
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
            txt = [txt; ['    glm.fit(x=x,y=Y, family= ' m.Y.family '() )']];
        case 'lmer'
            txt = [txt; ['    refit(mylme,Y)']];
    end
    txt = [txt;'}';{''}];
    
    %%%%%%%% end of estimation function
    %%% here we prepare the design matrix if necessary
    if not(Allatonce)
        switch m.type
            case 'glm'
            txt = [txt;
                'x <- model.matrix(' regexprep(formula,'.*(~.*)','$1') ')'];
            case 'lmer'
            txt = [txt;
                ['fid <- file(description = "' m.name '_dat.dat",open="rb" )']
                ['Y <- readBin(con=fid,what="numeric",n=nobss,size=4,endian="little")']
                'mylme <- lmer(' formula ', family=' m.Y.family '())'
                'close(fid)'];
        end
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
                txt = [txt;
                    'coefs = coef(res)'
                    'residuals = resid(res)'
                    checkdel([m.name '_coefs.dat']);
                    checkdel([m.name '_resids.dat']);
                    writebin([m.name '_coefs.dat'],'coefs')
                    writebin([m.name '_resids.dat'],'residuals')
                    ];
        end
    else
        % repeatedly (in a while loop) if we need to scan a bigger data file
        
        % first need to delete older files
        switch m.type
            case 'glm'
                txt = [txt;
                    {''}
                    checkdel([m.name '_coefs.dat']);
                    checkdel([m.name '_resids.dat']);];
            case 'lmer'
                txt = [txt;
                    {''}
                    checkdel([m.name '_coefs.dat']);
                    checkdel([m.name '_resids.dat']);];
        end
        
        txt = [txt;
            {''}
            % open file for reading
            ['fid <- file(description = "' m.name '_dat.dat",open="rb" )']
            % start while loop
            'while (T) {'
            % read chunck of data
            ['    dat <- readBin(con=fid,what="numeric",n=nblocs*nobss,size=4,endian="little")']
            % if we're done, break
            '    if (length(dat) == 0) break '
            % reshape data
            '    dim(dat) <- c(nobss,length(dat)/nobss)'
            % apply the model fit to that chunck
            '    res <- apply(dat,2,f)'
            ];
        switch m.type
            case 'glm'
                txt = [txt;
                    {''}
                    % extract coefs and resid
                    '    coefs = sapply(res,coef)'
                    '    residuals = sapply(res,resid)'
                    % save chunk of coefs and resid
                    writebin([m.name '_coefs.dat'],'coefs');
                    writebin([m.name '_resids.dat'],'residuals');
                    ];
            case 'lmer'
                txt = [txt;
                    {''}
                    % extract coefs and resid
                    '    ranefs = sapply(res,ranef)'
                    '    fixefs = sapply(res,fixef)'
                    '    residuals = sapply(res,resid)'
                    % save chunk of coefs and resid
                    writebin([m.name '_ranefs.dat'],'ranefs');
                    writebin([m.name '_fixefs.dat'],'fixefs');
                    writebin([m.name '_resids.dat'],'residuals');
                    ];
        end
        txt = [txt;
            '}'
            % done, close file
            'close(fid)'
            ];
        
        txt = [txt;
            ['writeMat("' m.name '_info.mat",coefs=attributes(res[[1]]$coefficients))']
            ];
        
    end
    %%%%%%%%%%%%% now actually write the R script.
    fid = fopen(fullfile(GIZ.wd,[m.name '.R']),'wt');
    for i = 1:numel(txt)
        fprintf(fid,'%s\n',txt{i});
    end
    fclose(fid);

    % and append one line to the batch
    fid = fopen(fullfile(GIZ.wd,'Runscript'),'at');
    str = ['R CMD BATCH ' [m.name '.R']];
    fprintf(fid,'%s\n',str);
    fclose(fid);
end
%%%%%%%%%%%%%%%%%% done. Run it!
if isunix
    !chmod +x Runscript
end
!./Runscript
%delete('Runscript')

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

