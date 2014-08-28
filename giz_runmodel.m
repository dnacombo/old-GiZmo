function GIZ = giz_runmodel(GIZ,imod,varargin)

% GIZ = giz_runmodel(GIZ)
% run the current model in R
% GIZ = giz_runmodel(GIZ,imod)
% run model imod
% GIZ = giz_runmodel(GIZ,imod, 'formula',form)
% use model formula form
% GIZ = giz_runmodel(GIZ,imod, 'nboot',nboot,'bootwhat',what)
% compute nboot bootstrap confidence intervals based on nboot non
% parametric bootstrap samples from the original 'what' statistic (default
% is TStat if omitted)
%
% This function prepares a Rscript and runs it.
% data and model frame should already be on disk.

if not(exist('GIZ','var'))
    GIZ = evalin('caller','GIZ');
end
defifnotexist('imod',GIZ.imod);
setdefvarargin(varargin,'formula',[],'nboot',[],'bootwhat','fixefs');

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
        disp(['Script for model ' num2str(imod) ' (' GIZ.model(imod).name ')'])
        if not(exist('form','var')) || isempty(form)
            % get the R default formula corresponding to the current model
            formula = giz_model_formula(GIZ,imod);
        else
            formula = form;
        end
        
        m = GIZ.model(imod);
        txt = {'require(R.matlab)'
            fastif(strcmp(m.type,'lmer'),'require(lme4)','')
            fastif(isempty(nboot),'','require(boot)')
            ''
            };
        
        
        % now need to create a R script and run it.
        
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
        % setup variables that are going to be useful to know how much we read
        txt = [txt
            'nobss <- nrow(GiZframe)'
            % we're going to process blocks of how_much_at_once models at once
            ['nblocs <- ' num2str(how_much_at_once)]
            {''}
            {''}
            % here we create a function that we'll run either once, or in blocks
            % of nblocs untill all the data has been modeled
            ['f <- function (Y){']
            ];
        
        
        switch m.type
            case 'glm'
                txt = [txt; ['  res <- glm.fit(x=x,y=Y, family= ' m.Y.family '() )']
                    % df.residual = df.error df.null = df.model
                    ['  res$fixefs <- res$coefficients']
                    ['  res$SSM <- sum((res$fitted.values - mean(Y))^2)']
                    ['  res$MSM <- res$SSM / res$df.null']
                    ['  res$SSE <- sum((Y - res$fitted.values)^2)']
                    ['  res$MSE <- res$SSE / res$df.residual']
                    ['  res$SST <- sum((Y - mean(Y))^2)']
                    ['  res$MST <- res$SST / (res$df.null + res$df.residual)']
                    ['  res$MFStat <- res$MSM / res$MSE'] % model Fstatistic
                    ['  res$Mpval <- 1 - pf(res$MFStat, res$df.null,res$df.residual)']
                    ['  res$SigmaSqE <- res$SSE/res$df.residual']
                    ['  res$VarCovar <- res$SigmaSqE * chol2inv(chol(t(x) %*% x))']
                    ['  res$StdErr <- sqrt(diag(res$VarCovar))']
                    ['  res$TStat <- res$coefficients/res$StdErr']
                    ['  res$pval <- 2*(1 - pt(abs(res$TStat),nrow(x)-ncol(x)))']
                    ['  return(res)']
                    ];
            case 'lmer'
                txt = [txt; ['  refit(mylme,Y)']];
        end
        txt = [txt;'}';{''}];
        %%%%%%%% end of estimation function
        %%%%%%%% Bootstrap function if needed
        error
        if not(isempty(nboot))
            txt = [txt; ['fb <- function (Y) {']
                '  s <- function(data,indices) {'
                '    Y <- data[indices]'
                ['    res <- f(Y)']
                ['    return(res$' bootwhat ')']
                '  }'
                ['  bci <- boot.ci(boot(data=Y,statistic=s,R=' num2str(nboot) '),conf=c(.025,.975),type="basic")']
                '  res <- f(Y)'
                ['  res$' bootwhat '.ci <- bci']
                '  return(res)'
                '}'
                ];
        end
        %%%%%%%% End of Bootstrap function
        %%% here we prepare the design matrix if necessary (GLM)
        % or run the model once (lme) to speed up upcoming computation
        switch m.type
            case 'glm'
                txt = [txt;
                    'x <- model.matrix(' regexprep(formula,'.*(~.*)','$1') ',data=GiZframe)'];
            case 'lmer'
                txt = [txt;
                    ['fid <- file(description = "' m.name '_dat.dat",open="rb" )']
                    ['GiZframe$Y <- readBin(con=fid,what="numeric",n=nobss,size=4,endian="little")']
                    'close(fid)'];
                switch m.Y.family
                    case 'gaussian'
                        txt = [txt;
                            ['mylme <- lmer(' formula ',data=GiZframe)']];
                    otherwise
                        txt = [txt;
                            ['mylme <- glmer(' formula ', family=' m.Y.family '(),data=GiZframe)']];
                end
        end
        
        %%%%%%%%
        % display a text progress bar
        datf = dir(fullfile(GIZ.wd,[m.name '_dat.dat']));
        txt = [txt;'pb <- txtProgressBar(min=0,max=ceiling(' num2str(datf.bytes/4) '/nobss/nblocs),style = 3)'];
        txt = [txt;'i <- 0';];
        %%%%%%%%
        
        % now actually run the model
        % repeatedly (in a while loop)
        
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
            'while (T) {'];
        % read chunck of data
        if isempty(m.Y.event) || isnumeric(GIZ.DATA{m.Y.idat}.event(1).(m.Y.event))
            txt = [txt;
                ['  dat <- readBin(con=fid,what="numeric",n=nblocs*nobss,size=4,endian="little")']
                ];
        else
            txt = [txt;
                '  dat <- readLines(con=fid,n=nblocs*nobss,ok=T)'
                ];
        end
        txt = [txt;
            % if we're done, break
            '  if (length(dat) == 0) break '
            % reshape data
            '  dim(dat) <- c(nobss,length(dat)/nobss)'
            % apply the model fit to that chunck
            fastif(isempty(nboot),'  res <- apply(dat,2,f)','  res <- apply(dat,2,fb)')
            % display a text progress bar
            '  i <- i + 1'
            '  setTxtProgressBar(pb, i)'
            %%%%%%%%
            ];
        switch m.type
            case 'glm'
                txt = [txt;
                    {''}
                    % extract coefs and resid
                    '  coefs <- sapply(res,coef)'
                    '  StdErr <- sapply(res,function(x){x$StdErr})'
                    '  residuals <- sapply(res,resid)'
                    '  TStats <- sapply(res,function(x){x$TStat})'
                    '  pvals <- sapply(res,function(x){x$pval})'
                    % save chunk of coefs and resid
                    writebin([m.name '_fixefs.dat'],'coefs');
                    writebin([m.name '_stderr.dat'],'StdErr');
                    writebin([m.name '_resids.dat'],'residuals');
                    writebin([m.name '_TStats.dat'],'TStats');
                    writebin([m.name '_pvals.dat'],'pvals');
                    ];
            case 'lmer'
                txt = [txt;
                    {''}
                    % extract coefs and resid
                    '  ranefs <- c(sapply(res,ranef),recursive=T)'
                    '  fixefs <- sapply(res,fixef)'
                    '  residuals <- sapply(res,resid)'
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
                    ['writeMat("' m.name '_info.mat",fixefs=attributes(res[[1]]$coefficients),TStats=attributes(res[[1]]$coefficients)),pvals=attributes(res[[1]]$coefficients))']
                    ];
            case 'lmer'
                txt = [txt;
                    ['writeMat("' m.name '_info.mat",ranefs=list(names=colnames(ranef(res[[1]])[[1]])),fixefs=list(names=names(fixef(res[[1]]))))']
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
    disp('Done!')
else
    error('todo')
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
    ['  fud <- file(description = "' fname '",open="ab" )']
    ['  ok <- writeBin(object=as.vector(' datvar '),con=fud,size=4,endian="little")']
    '  close(fud)'
    };


function txt = checkdel(fname)

txt = {
    ['if (file.exists("' fname '")) file.remove("' fname '")']
    };

