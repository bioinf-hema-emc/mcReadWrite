
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mcReadWrite

<!-- badges: start -->

<!-- badges: end -->

The goal of mcReadWrite is to …

## Installation

You can install the development version of mcReadWrite from
[GitHub](https://github.com/) with:

``` r
devtools::install_github("bioinf-hema-emc/mcReadWrite")
```

## Requirements

This package are only tested on Ubuntu 24.03. The functions in this
package require the following system functions to be installed:

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

### mcloadEnvironment

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
#  77.240  14.935  92.001

system.time(mcreadRDS("myObject.RDS"))
#   user  system elapsed 
# 76.652  30.079  41.281 


# MCSAVE.IMAGE ----
system.time(save.image('myEnvironment.RData'))
#   user  system elapsed 
# 34.728  29.664  66.836
# RData file size = 24Gb

system.time(mcsave.image('myEnvironment.RData'))
```
