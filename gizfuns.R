



gizglm <- function (formula, basename = 'gizmo', nblocks = 1000, family=gaussian(), asfactors = NULL, ...){
  
  df = read.table(paste0(basename,'.df'),header=T)
  if (!is.na(asfactors)) {
    for (i in 1:length(asfactors)){
      if (asfactors[i]){
        df[,i] = as.factor(df[,i])
      } else {
        df[,i] = as.numeric(df[,i])
      }
    }
  }
  nobs = nrow(df)
  
  x <- model.matrix(formula, data = df)
  delifexist(paste0(basename,'_design.dat'))
  res2file(paste0(basename,'_design.dat'),x)
  
  f <- function (y){
    res = glm.fit(x,y,family=family)
  }
  delifexist(paste0(basename,'_coefs.dat'))
  delifexist(paste0(basename,'_resids.dat'))

    fid <- file(description = paste0(basename,'.dat'),open="rb" )
    while (T) {
      dat <- readBin(con = fid,
                     what="numeric",
                     n=nblocks * nobs,
                     size=4,
                     endian="little")
      if (length(dat) == 0) break
      
      dim(dat) <- c(nobs,length(dat)/nobs)
      res <- apply(dat,2,f)
      
      coefs = sapply(res,coef)
      resids = sapply(res,resid)
      
      res2file(paste0(basename,'_coefs.dat'),coefs)
      res2file(paste0(basename,'_resids.dat'),resids)
      
    }
  close(fid)
}

res2file <- function(fname,dat){
  fud <- file(description = fname, open="ab")
  ok <- writeBin(object = as.vector(dat), con=fud, size=4, endian="little")
  close(fud)
}

delifexist <- function(fname){
  if (file.exists(fname)) file.remove(fname)
}



