################################################################################
### Author:		Gregory van Beek
### Date:	        18-12-2025
### Email:          	g.vanbeek@erasmusmc.nl
###
### Version:        	1.0.0
###
### Description:    	Loads functions to read and write RDS files and RData files multicore
###                 	It loads the following functions:
###                     	mcsaveRDS()
###                     	mcreadRDS()
###                     	mcsave.image()
###                     	mcsaveEnvironment()
###                     	mcloadEnvironment()
################################################################################

#' mcsaveRDS
#' 
#' This is a multicore version of the default `saveRDS()` function.
#' It requires a significantly shorter time to save RDS files.
#' It uses igzip which automatically compresses the RDS files.
#' Typically the performance does not increase anymore when using more than 4 cores.
#' When cores = 1, this functions uses the default `saveRDS()` function.
#' 
#' @param object Variable, object or function to be saved.
#' @param file String. Path where the RDS file needs to be stored.
#' @param compression_level Integer. Default = 3. Value between 1 and 3. Higher values means better compression, but also requires more time.
#' @param cores Integer. Default = 4. How many cores to use for saving. Typically setting this higher than 4 does not yield better performance.
#'
#' @examples
#' \dontrun{
#' mcsaveRDS(myObj, file = 'myObj.RDS')
#' }
#' 
#' @export
mcsaveRDS <- function(object,file,compression_level=3,cores=4){
  if(cores > 1){
    con <- pipe(paste0("bash -l -c 'module load isal && igzip -z -c -",compression_level," -T",cores," > ",file, "'"),"wb")
    saveRDS(object, file = con)
    close(con)
  } else {
    saveRDS(object, file = file)
  }
}



#' mcreadRDS
#' 
#' This is a multicore version of the default `readRDS()` function.
#' It requires a significantly shorter time to read RDS files.
#' It uses rapidgzip to decompress RDS files and load them into your environment.
#' Typically the performance does not increase anymore when using more than 4 cores.
#' When cores = 1, this functions uses the default `readRDS()` function.
#' 
#' @param file String. Path where the RDS file needs to be stored.
#' @param cores Integer. Default = 4. How many cores to use for saving. Typically setting this higher than 4 does not yield better performance.
#' @return R-object
#' 
#' @examples
#' \dontrun{
#' myObj <- mcreadRDS('myObj.RDS')
#' }
#'
#' @export
mcreadRDS <- function(file,cores=4) {
  if(cores > 1){
    con <- pipe(paste0("bash -l -c 'rapidgzip -d -c -P",cores," ",file,"'"), "rb")
    object <- readRDS(file = con)
    close(con)
  } else {
    object <- readRDS(file = file)
  }
  return(object)
}



#' mcsave.image
#'
#' This is a multicore version of save.image().
#' It uses igzip that automatically compresses the RData file.
#' It is not faster perse than `save.image()` without compression, but this function automatically compresses the RData file in the about same time as `save.image()` without compression.
#'
#' @param file String. Path to Rdata file where the environment needs to be saved.
#' @param compression_level Integer. Default = 3. Should be a value between 0 and 3.
#' @param cores Integer. Default = 4. How many cores to be used. Usually more than 4 cores does not yield much performance gains.
#' @usage mcsave.image(file = 'myEnvironment.RData')
#'
#' @export
mcsave.image <- function(file=".RData", compression_level = 2, cores=4){
 if(cores > 1){
   if(cores < 1 || ! is.numeric(cores)){
     print("Warning: Enter integer between 1 and 4. Resetting cores <- 1")
   }
 }

 if(compression_level > 3){
   compression_level = 3
 }
 if(cores > 1){
   con <- pipe(paste0("bash -l -c 'module load isal && igzip -z -c -",
                      compression_level ," -T",cores," > ",file, "'"),"wb")
   save(list = ls(all.names = T, envir=parent.frame()), file = con, envir=parent.frame())
   close(con)
   } else {
   save.image(file = file)
   }
}



#' mcsaveEnvironment
#'
#' Save an R environment using multiple compute cores.
#' This function is faster than the default `save.image()` and `mcsave.image()`.
#' Instead of saving the environment in a single .RData file (e.g. as is done with the default function `save.image()`), this creates a folder where each object, variable and function is stored as a separate file.
#' Each of these RData files can loaded in individually using `load()`, or the entire environment can be loaded from this folder using `mcloadEnvironment()`.
#' This functions automatically loads the parallel package.
#'
#' @param savepath String. Path to where to save the RData files. If it does not exists, it will be created. Best to use an empty or non-existing path.
#' @param save_functions Default: TRUE. TRUE/FALSE. Whether to store functions.
#' @param cores Integer. Default: 10. How many cores should be used for saving. Should be a value between 1 and 10.
#' @param compress TRUE/FALSE. Default:FALSE. Whether to use compression. This can make the files about half the size, but requires more time.
#' @param compression_level Integer. Default: 3. Should be a value between 0 and 3. Higher compression means smaller files, but also requires more time. Only relevant when `compress = TRUE`.
#' @usage mcsaveEnvironment(savepath = '/path/to/empty/directory', cores = 10)
#'
#' @export
mcsaveEnvironment <- function(savepath, save_functions = T, cores = 10, compress = F, compression_level = 3){
    require("parallel")

    if(! file.exists(savepath)){
	dir.create(savepath)
    } 

    if(! length(list.files(savepath)) == 0){
	stop('Error: Folder is not empty. Please enter an empty or non-existing folder.')
    }

    if(cores > 10){
        print('Maximum allowed cores is 10. Resetting cores to 10')
        cores <- 10
    } else if(cores < 1 || ! is.numeric(cores)){
        print('Invalid value for cores. Resetting cores to 1')
        cores <- 1
    }

    env_list <- ls(all.names = T, envir = .GlobalEnv)
    ## Don't save functions from this script and hidden variables
    env_list <- env_list[grep('^\\.|mcsaveEnvironment|mcloadEnvironment', env_list, invert = T)]

    if(save_functions == FALSE){
        env_list <- env_list[unlist(lapply(env_list, function(x){! is.function(get(x))}))]
    }

    if(compress == T){

        env_list <- env_list[grep('.mcload|.mcsave', env_list, invert = T)] #Don't save source functions

        mclapply(seq(env_list), function(x){
            .mcsave(obj_list = env_list[x], file = file.path(savepath, paste0(env_list[x], '.RData')),
                    compression_level = compression_level, cores = 1)
        }, mc.cores = cores)

    } else {

        mclapply(seq(env_list), function(x){
            save(list = env_list[x], file = file.path(savepath, paste0(env_list[x], '.RData')), compress = F)
        }, mc.cores = cores)

    }
}



#' mcloadEnvironment
#'
#' Load an R environment that was saved using `mcsaveEnvironment()`.
#'
#' @param loadpath String. Path to a folder where the output of `mvsaveEnvironment()` is stored.
#' @param cores Integer. Default: 10. How many cores should be used for saving. Should be a value between 1 and 10.
#' @usage mcloadEnvironment(loadpath = '/path/to/mcsaveEnvironment/directory', cores = 10)
#'
#' @export
mcloadEnvironment <- function(loadpath, cores = 10){
    if(! dir.exists(loadpath)){
      stop("This function only loads directories stored with mcsaveEnvironment(). To load RData objects, use load().")
    }

    require("parallel")

    if(cores > 10){
        print('Maximum allowed cores is 10. Resetting cores to 10')
        cores <- 10
    } else if(cores < 1 || ! is.numeric(cores)){
        print('Invalid value for cores. Resetting cores to 1')
        cores <- 1
    }

    env_list <- list.files(loadpath, pattern = 'RData', full.names = T)

    tempenv <- new.env()
    loaded_objs <- mclapply(env_list, function(x){
                            objs <- load(x, envir = tempenv)
                            mget(objs, envir = tempenv)
    }, mc.cores = cores)

    loaded_objs <- do.call(c, loaded_objs)

    list2env(loaded_objs, envir = .GlobalEnv)
}



.mcsave <- function(obj_list, file=".RData", compression_level = 3, threads=4){
  if(compression_level > 3){
      print('Maximum compression level is 3. Resetting compression level to 3')
      compression_level = 3
  } else if(compression_level < 0 | ! is.numeric(compression_level)){
      print('0 <= Compression_level >= 3. Resetting to 0')
      compresssion_level <- 0
  }
  con <- pipe(paste0("bash -l -c 'module load isal && igzip -z -c -", compression_level ," -T",threads," > ",file, "'"),"wb")
  save(list = obj_list, file = con, envir=parent.frame())
  close(con)
}

