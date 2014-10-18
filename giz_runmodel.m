function GIZ = giz_runmodel(GIZ,imod,form)

% GIZ = giz_runmodel(GIZ)
% run the current model in R
% GIZ = giz_runmodel(GIZ,imod)
% run model imod
% GIZ = giz_runmodel(GIZ,imod, form)
% use model formula form
%
% This function prepares a Rscript and runs it.
% data and model frame should already be on disk.

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end
defifnotexist('imod',GIZ.imod);

cd(GIZ.wd);
how_much_at_once = 1000;
if GIZ.useR
    Rpath = giz_checkR;
    if not(Rpath)
        error('must install R')
    else
        disp('R is installed properly.')
    end
    % Initialize batch
    fid = fopen(fullfile(GIZ.wd,'Runscript'),'wt');
    if not(isempty(Rpath))
        str = ['set PATH=' Rpath ';%%PATH%%'];
        fprintf(fid,'%s\n',str);
    end
    fclose(fid);
    
    Routs = {};
    % for all the models we want to run
    for imod = imod
        disp(['Running model ' num2str(imod) '(' GIZ.model(imod).name ')'])
        if not(exist('form','var'))
            % get the R default formula corresponding to the current model
            formula = giz_model_formula(GIZ,imod);
        else
            formula = form;
        end

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
        
        
        switch m.type
            case 'glm'
                txt = [txt; ['    res <- glm.fit(x=x,y=Y, family= ' m.Y.family '() )']
                    ['    res$SigmaSq <- sum((Y - x %*% res$coefficients)^2)/(nrow(x)-ncol(x))']
                    ['    res$VarCovar <- res$SigmaSq * chol2inv(chol(t(x) %*% x))']
                    ['    res$StdErr <- sqrt(diag(res$VarCovar))']
                    ['    res$TStat <- res$coefficients/res$StdErr']
                    ['    res$pval <- 2*(1 - pt(abs(res$TStat),nrow(x)-ncol(x)))']
                    ['    return(res)']
                    ];
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
                        ['GiZframe$Y <- readBin(con=fid,what="numeric",n=nobss,size=4,endian="little")']
                        'close(fid)'];
                    switch m.Y.family
                        case 'gaussian'
                            txt = [txt;
                                ['mylme <- lmer(' formula ')']];
                        otherwise
                            txt = [txt;
                                ['mylme <- glmer(' formula ', family=' m.Y.family '())']];
                    end
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
                        'coefs <- coef(res)'
                        'residuals <- resid(res)'
                        'TStats <- res$TStat'
                        'pvals <- res$pval'
                        checkdel([m.name '_fixefs.dat']);
                        checkdel([m.name '_resids.dat']);
                        checkdel([m.name '_TStats.dat']);
                        checkdel([m.name '_pvals.dat']);
                        writebin([m.name '_fixefs.dat'],'coefs')
                        writebin([m.name '_resids.dat'],'residuals')
                        writebin([m.name '_TStats.dat'],'TStats')
                        writebin([m.name '_pvals.dat'],'pvals')
                        ];
                case 'lmer'
                    error('todo')
                    txt = [txt;
                        'residuals <- resid(res)'
                        'ranefs <- ranef(res)'
                        'fixefs <- fixef(res)'
                        checkdel([m.name '_ranefs.dat']);
                        checkdel([m.name '_fixefs.dat']);
                        checkdel([m.name '_resids.dat']);
                        writebin([m.name '_ranefs.dat'],'ranefs')
                        writebin([m.name '_fixefs.dat'],'fixefs')
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
                        checkdel([m.name '_fixefs.dat']);
                        checkdel([m.name '_resids.dat']);
                        checkdel([m.name '_TStats.dat']);
                        checkdel([m.name '_pvals.dat']);
                        ];
                case 'lmer'
                    txt = [txt;
                        {''}
                        checkdel([m.name '_resids.dat']);
                        checkdel([m.name '_ranefs.dat']);
                        checkdel([m.name '_fixefs.dat']);
                        ];
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
                        '    coefs <- sapply(res,coef)'
                        '    residuals <- sapply(res,resid)'
                        '    TStats <- sapply(res,function(x){x$TStat})'
                        '    pvals <- sapply(res,function(x){x$pval})'
                        % save chunk of coefs and resid
                        writebin([m.name '_fixefs.dat'],'coefs');
                        writebin([m.name '_resids.dat'],'residuals');
                        writebin([m.name '_TStats.dat'],'TStats');
                        writebin([m.name '_pvals.dat'],'pvals');
                        ];
                case 'lmer'
                    txt = [txt;
                        {''}
                        % extract coefs and resid
                        '    ranefs <- c(sapply(res,ranef),recursive=T)'
                        '    fixefs <- sapply(res,fixef)'
                        '    residuals <- sapply(res,resid)'
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
            switch m.type
                case 'glm'
                    txt = [txt;
                        ['writeMat("' m.name '_info.mat",fixefs=attributes(res[[1]]$coefficients)),TStats=attributes(res[[1]]$coefficients))']
                        ];
                case 'lmer'
                    txt = [txt;
                        ['writeMat("' m.name '_info.mat",ranefs=list(names=colnames(ranef(res[[1]])[[1]])),fixefs=list(names=names(fixef(res[[1]]))))']
                        ];
            end
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
        Routs{end+1} = fullfile(GIZ.wd,[m.name '.Rout']);
    end
    %%%%%%%%%%%%%%%%%% done. Run it!
    if isunix
        !chmod +x Runscript
    end
    disp('Now running script in R...')
    fprintf(['see\n' sprintf('%s\n',Routs{:})  'to follow the process...\n'])
    !./Runscript
    delete('Runscript')
else
    for imod = imod
        m = GIZ.model(imod);
        if strcmp(m.type,'lme') && ~strcmp(m.Y.family,'gaussian')
            error('Matlab can''t estimate a mixed effect binomial model. Use R.');
        end
        Allatonce = isempty(m.Y.dimsplit);
        GiZds = dataset('File',[m.name '_frame.txt'],'ReadVarNames',1);
        for i_X = 1:numel(m.X)
            if m.X(i_X).isfact
                GiZds.(m.X(i_X).event) = nominal(GiZds.(m.X(i_X).event));
            end
        end
        if not(Allatonce)
            nobss = size(GiZds,1);
            nblocks = how_much_at_once;
        end
        formula = giz_model_formula(GIZ);
        if Allatonce
            switch m.type
                case 'glm'
                    parsed = classreg.regr.LinearMixedFormula(formula,GiZds.Properties.VarNames);
                    Yname = parsed.ResponseName;
                    Y = GiZds.(Yname);
                    Xnames = parsed.PredictorNames;
                    i_x = 1;
                    for i = 1:numel(Xnames)
                        % here I need to create dummyvars properly
                        % i.e. all at once by passing all nominal 
                        % vars of GiZds to dummyvar at once.
                        error
                        if strcmp(class(GiZds.(Xnames{i})),'nominal')
                           ix = dummyvar(GiZds.(Xnames{i}));
                        else
                            ix = GiZds.(Xnames{i});
                        end
                        X(:,i_x:i_x+size(ix,2)-1) = ix;
                        i_x = size(X,2)+1;
                    end
                    [b dev stat] = glmfit(X,Y,m.Y.family);
                    res = struct('b',b,'dev',dev,'stat',stat);
                case 'lme'
                    res = fitlme(GiZds,formula,'Verbose',true);
            end
        else
        datf = dir(fullfile(GIZ.wd,[m.name '_dat.dat']));
            fid = fopen(datf,'rb','l');
            while 1
                d = fread(fid,Inf,'single=>single');
                if numel(d) == 0
                    break
                end
                d = reshape(d,nobss, []);
                for i_d = 1:size(d,2)
                    GiZds.Y = d(:,i_d);
                    res(i_d) = fitlme(GiZds,formula);
                end
                keyboard
                % write res.coefs etc as files (see lines ~190)
            end
            fclose(fid);

        end
    end
end

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

