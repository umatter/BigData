# load packages
library(data.table)

# load example data from basic R installation
data("LifeCycleSavings")

# write data to normal csv file and check size
fwrite(LifeCycleSavings, file="lcs.csv")
file.size("lcs.csv")

# write data to a GZIPped (compressed) csv file and check size
fwrite(LifeCycleSavings, file="lcs.csv.gz")
file.size("lcs.csv.gz")

# read/import the compressed data
lcs <- data.table::fread("lcs.csv.gz")

# common ZIP compression (independent of data.table package)
write.csv(LifeCycleSavings, file="lcs.csv")
file.size("lcs.csv")
zip(zipfile = "lcs.csv.zip", files =  "lcs.csv")
file.size("lcs.csv.zip")

# unzip/decompress and read/import data
lcs_path <- unzip("lcs.csv.zip")
lcs <- read.csv(lcs_path)





# you can download the dataset from 
# https://www.kaggle.com/jackdaoud/marketing-data?
# select=marketing_data.csv

# PREPARATION -----------------------------
# packages
library(stringr)

# import data
marketing <- read.csv("data/marketing_data.csv")
# clean/prepare data
marketing$Income <- as.numeric(gsub("[[:punct:]]",
                                    "",
                                    marketing$Income)) 
marketing$days_customer <- 
     as.Date(Sys.Date())- 
     as.Date(marketing$Dt_Customer, "%m/%d/%y")
marketing$Dt_Customer <- NULL

# all sets of independent vars
indep <- names(marketing)[ c(2:19, 27,28)]
combinations_list <- lapply(1:length(indep),
                            function(x) combn(indep, x,
                                              simplify = FALSE))
combinations_list <- unlist(combinations_list, 
                            recursive = FALSE)
models <- lapply(combinations_list,
                 function(x) paste("Response ~", 
                                   paste(x, collapse="+")))

# COMPUTE REGRESSIONS --------------------------
N <- 10 #  N <- length(models) for all
pseudo_Rsq <- list()
length(pseudo_Rsq) <- N
for (i in 1:N) {
  # fit the logit model via maximum likelihood
  fit <- glm(models[[i]],
             data=marketing,
             family = binomial())
  # compute the proportion of deviance explained by 
  # the independent vars (~R^2)
  pseudo_Rsq[[i]] <- 1-(fit$deviance/fit$null.deviance)
}

# SELECT THE WINNER ---------------
models[[which.max(pseudo_Rsq)]]


# COMPUTE REGRESSIONS --------------------------
N <- 10 #  N <- length(models) for all
run_reg <- 
     function(model, data, family){
          # fit the logit model via maximum likelihood
          fit <- glm(model, data=data, family = family)
          # compute and return the proportion of deviance explained by 
          # the independent vars (~R^2)
          return(1-(fit$deviance/fit$null.deviance))
     }

pseudo_Rsq_list <-lapply(models[1:N], run_reg, data=marketing, family=binomial() )
pseudo_Rsq <- unlist(pseudo_Rsq_list)

# SELECT THE WINNER ---------------
models[[which.max(pseudo_Rsq)]]



# SET UP ------------------

# load packages
library(future)
library(future.apply)
# instruct the package to resolve
# futures in parallel (via a SOCK cluster)
plan(multisession)

# COMPUTE REGRESSIONS --------------------------
N <- 10 #  N <- length(models) for all
pseudo_Rsq_list <- future_lapply(models[1:N],
                                 run_reg,
                                 data=marketing,
                                 family=binomial() )
pseudo_Rsq <- unlist(pseudo_Rsq_list)

# SELECT THE WINNER ---------------
models[[which.max(pseudo_Rsq)]]


# COMPUTE REGRESSIONS IN PARALLEL (MULTI-CORE) --------------------------

# packages for parallel processing
library(parallel)
library(doSNOW)

# get the number of cores available
ncores <- parallel::detectCores()
# set cores for parallel processing
ctemp <- makeCluster(ncores)
registerDoSNOW(ctemp)

# prepare loop
N <- 10000 #  N <- length(models) for all
# run loop in parallel
pseudo_Rsq <-
  foreach ( i = 1:N, .combine = c) %dopar% {
    # fit the logit model via maximum likelihood
    fit <- glm(models[[i]], 
               data=marketing,
               family = binomial())
    # compute the proportion of deviance explained by 
    # the independent vars (~R^2)
    return(1-(fit$deviance/fit$null.deviance))
}

# SELECT THE WINNER ---------------
models[[which.max(pseudo_Rsq)]]


# COMPUTE REGRESSIONS IN PARALLEL (MULTI-CORE) ---------------


# prepare parallel lapply (based on forking, 
# here clearly faster than foreach)
N <- 10000 #  N <- length(models) for all
# run parallel lapply
pseudo_Rsq <- mclapply(1:N,
                       mc.cores = ncores,
                       FUN = function(i){
                         # fit the logit model 
                         fit <- glm(models[[i]],
                                    data=marketing,
                                    family = binomial())
                         # compute the proportion of deviance 
                         # explained  by the independent vars (~R^2)
                         return(1-(fit$deviance/fit$null.deviance))
                         })

# SELECT THE WINNER, SHOW FINAL OUTPUT ---------------

best_model <- models[[which.max(pseudo_Rsq)]]
best_model






# load package
library(bench)
library(gpuR)


# initialize dataset with pseudo-random numbers
N <- 10000  # number of observations
P <- 100 # number of variables
X <- matrix(rnorm(N * P, 0, 1), nrow = N, ncol =P)


# prepare GPU-specific objects/settings
# transfer matrix to GPU (matrix stored in GPU memory)
vclX <- vclMatrix(X, type = "float")  

# compare three approaches
gpu_cpu <- bench::mark(
  
  # compute with CPU 
  cpu <-t(X) %*% X,
  
  # GPU version, in GPU memory 
  # (vclMatrix formation is a memory transfer)
  gpu <- t(vclX) %*% vclX,
 
check = FALSE, memory = FALSE, min_iterations = 200)

plot(gpu_cpu, type = "boxplot")

include_graphics("img/gpu_cpu.png")
