
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mcReadWrite

<!-- badges: start -->

<!-- badges: end -->

Parallel reading and writing of RDS and RData files

## Installation

You can install the development version of mcReadWrite from
[GitHub](https://github.com/) with:

``` r
devtools::install_github("bioinf-hema-emc/mcReadWrite")
```

## Requirements

This package are only tested on Ubuntu 24.04.3 LTS. The functions in
this package require the following system functions to be installed:

- [igzip](https://manpages.debian.org/testing/isal/igzip.1.en.html)
  (from the isal-package)
- [rapidgzip](https://pypi.org/project/rapidgzip/0.0.1/)

## Functions

The following functions are available in this package:

- mcsaveRDS
- mcreadRDS
- mcsave.image
- mcsaveEnvironment
- mcloadEnvironment

See the details section below for more information.

## Details

There is no multicore equivalent function for the `load()` function
(loading RData environment files). The multicore version proofed not to
be significantly quicker than the default load function. As an
alternative there is the mcloadEnvironment function. See details below.

### mcsaveRDS

This is a multicore version of the default `saveRDS()` function. It
requires a significantly shorter time to save RDS files. It uses igzip
which automatically compresses the RDS files. Typically the performance
does not increase anymore when using more than 4 cores. When cores = 1,
this functions uses the default `saveRDS()` function.

The function accepts four parameters, the object to be saved, a filepath
where the RDS needs to be saved, an optional compression level and the
number of cores. It uses igzip with the command
`igzip -z -c -{compression_level} -T{cores}" > {file}`. The compression
level by default is set to 3, but can be changed between values 0 and 3.
Higher values means better compression, but also requires more time.
Note that igzip always use some compression, even when set to 0.

### mcreadRDS

This is a multicore version of the default `readRDS()` function. It
requires a significantly shorter time to read RDS files. It uses
rapidgzip to decompress RDS files and load them into your environment.
Typically the performance does not increase anymore when using more than
4 cores. When cores = 1, this functions uses the default `readRDS()`
function.

The functions accepts two parameters, the filepath of an RDS-object and
the number of cores. It uses rapidgzip to read the file using the
command `rapidgzip -d -c -P{cores} {file}`.

### mcsave.image

This is a multicore version of `save.image()`. It uses igzip that
automatically compresses the RData file. It is not faster perse than
`save.image()` without compression, but this function automatically
compresses the RData file in the about same time as `save.image()`
without compression.

The function accepts three parameters, a filepath where the RData needs
to be saved, an optional compression level and the number of cores. It
uses igzip with the command
`igzip -z -c -{compression_level} -T{cores}" > {file}`. The compression
level by default is set to 3, but can be changed between values 0 and 3.
Higher values means better compression, but also requires more time.
Note that igzip always use some compression, even when set to 0.

### mcsaveEnvironment

Save an R environment using multiple compute cores. This function is
faster than the default `save.image()` and `mcsave.image()`. Instead of
saving the environment in a single .RData file (e.g. as is done with the
default function `save.image()`), this creates a folder where each
object, variable and function is stored as a separate file. Each of
these RData files can loaded in individually using `load()`, or the
entire environment can be loaded from this folder using
`mcloadEnvironment()`. The reason the files are saved as RData instead
of RDS (as is more common when saving individual variables) is because
RData files also stores the name of the variable in contrast to RDS
files which you have the name again when loading (using readRDS). This
functions automatically loads the parallel package.

This function takes 5 parameters, a path to an empty folder where the
RDS files are stored, the number of cores, whether functions need to be
saved (TRUE by default), whether to use compression (FALSE by default,
makes the function really slow but does save storage space) and the
compression level for igzip (defaults to 3). When the folder does not
exists, it will be created. The folder needs to be empty, otherwise the
function throws an error. In this case, either remove all files in the
folder or enter a different, empty, folder. The number of cores defaults
to 10.

This function saves the environment slightly faster than
`mcsave.image()` and `save.image()`, but loading the entire environment
using `mcloadEnvironment()` requires more time compared to using
`load()` with an RData file. Therefore, the combination of
`mcsaveEnvironment` and `mcloadEnvironment` will not gain you time with
saving and loading the environment, but the way it stores the
environment can be more convenient in some cases. Instead of saving the
entire environment in a single RData file, this stores each object,
value and function as an individual RData files. When you only want to
load some objects from the environment, this allows you to only load
those instead of having to load the whole environment first.

### mcloadEnvironment

Load an R environment that was saved using `mcsaveEnvironment()`.

This function takes 2 parameters, a path to a folder where the RDS files
are stored using `mcsaveEnvironment()` and the number of cores.

## Example

``` r
library(mcReadWrite)

file.size("myObject.RDS")
# [1] 11146631571 # RDS file size = 11Gb; Loaded object in environment = 19.5Gb

# myEnvironment contains 5 objects, 12 values and a function with a total of 23Gb.



# MCSAVERDS ----
system.time(saveRDS(myObj, "myObject.RDS"))
#    user  system elapsed 
# 498.945  18.832 516.975

system.time(mcsaveRDS(myObj, "myObject.RDS"))
#   user  system elapsed 
# 98.074  62.129  59.181



# MCLOADRDS ----
system.time(readRDS("myObject.RDS"))
#   user  system elapsed 
# 77.240  14.935  92.001

system.time(mcreadRDS("myObject.RDS"))
#   user  system elapsed 
# 76.652  30.079  41.281 



# MCSAVE.IMAGE ----
system.time(save.image('myEnvironment.RData'))
#   user  system elapsed 
# 33.935  35.957  73.919 
# RData file size = 24Gb

system.time(mcsave.image('myEnvironment.RData'))
#    user  system elapsed 
# 151.206  92.672  86.360 
# RData file size = 13Gb



# MCSAVEENVIRONMENT ----
system.time(mcsaveEnvironment('myEnvironment'))
# Loading required package: parallel
#   user  system elapsed 
# 13.339  17.531  49.259 
# Folder size = 24Gb.



# MCLOADENVIRONMENT ----
system.time(load('myEnvironment.RData'))
#   user  system elapsed 
# 96.137  22.682 118.585 

system.time(mcloadEnvironment('myEnvironment'))
# Loading required package: parallel
#    user  system elapsed 
# 211.311  74.591 210.07
```
