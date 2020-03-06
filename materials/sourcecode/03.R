## -------------------------------------------------------------------------------------------------
url <- "https://vincentarelbundock.github.io/Rdatasets/csv/carData/MplsStops.csv"
stopdata <- read.csv(url)


## -------------------------------------------------------------------------------------------------
# remove incomplete obs
stopdata <- na.omit(stopdata)
# code dependent var
stopdata$vsearch <- 0
stopdata$vsearch[stopdata$vehicleSearch=="YES"] <- 1
# code explanatory var
stopdata$white <- 0
stopdata$white[stopdata$race=="White"] <- 1


## -------------------------------------------------------------------------------------------------
model <- vsearch ~ white + factor(policePrecinct)


## -------------------------------------------------------------------------------------------------
fit <- lm(model, stopdata)
summary(fit)


## ----message=FALSE--------------------------------------------------------------------------------
# load packages
library(data.table)
# set the 'seed' for random numbers (makes the example reproducible)
set.seed(2)

# set number of bootstrap iterations
B <- 10
# get selection of precincts
precincts <- unique(stopdata$policePrecinct)
# container for coefficients
boot_coefs <- matrix(NA, nrow = B, ncol = 2)
# draw bootstrap samples, estimate model for each sample
for (i in 1:B) {
     
     # draw sample of precincts (cluster level)
     precincts_i <- sample(precincts, size = 5, replace = TRUE)
     # get observations
     bs_i <- lapply(precincts_i, function(x) stopdata[stopdata$policePrecinct==x,])
     bs_i <- rbindlist(bs_i)
     
     # estimate model and record coefficients
     boot_coefs[i,] <- coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
}


## -------------------------------------------------------------------------------------------------
se_boot <- apply(boot_coefs, 
                 MARGIN = 2,
                 FUN = sd)
se_boot


## ----message=FALSE--------------------------------------------------------------------------------
# install.packages("doSNOW", "parallel")
# load packages for parallel processing
library(doSNOW)

# get the number of cores available
ncores <- parallel::detectCores()
# set cores for parallel processing
ctemp <- makeCluster(ncores) # 
registerDoSNOW(ctemp)


# set number of bootstrap iterations
B <- 10
# get selection of precincts
precincts <- unique(stopdata$policePrecinct)
# container for coefficients
boot_coefs <- matrix(NA, nrow = B, ncol = 2)

# bootstrapping in parallel
boot_coefs <- 
     foreach(i = 1:B, .combine = rbind, .packages="data.table") %dopar% {
          
          # draw sample of precincts (cluster level)
          precincts_i <- sample(precincts, size = 5, replace = TRUE)
          # get observations
          bs_i <- lapply(precincts_i, function(x) stopdata[stopdata$policePrecinct==x,])
          bs_i <- rbindlist(bs_i)
          
          # estimate model and record coefficients
          coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
      
     }


# be a good citizen and stop the snow clusters
stopCluster(cl = ctemp)




## -------------------------------------------------------------------------------------------------
se_boot <- apply(boot_coefs, 
                 MARGIN = 2,
                 FUN = sd)
se_boot


## ----eval = FALSE---------------------------------------------------------------------------------
## ###########################################################
## # Big Data Statistics: Flights data import and preparation
## #
## # U. Matter, January 2019
## ###########################################################
## 
## # SET UP -----------------
## 
## # fix variables
## DATA_PATH <- "../data/flights.csv"
## 
## # DATA IMPORT ----------------
## flights <- read.csv(DATA_PATH)
## 
## # DATA PREPARATION --------
## flights <- flights[,-1:-3]
## 
## 
## 


## -------------------------------------------------------------------------------------------------

# SET UP -----------------

# fix variables
DATA_PATH <- "materials/data/flights.csv"
# load packages
library(pryr) 


# check how much memory is used by R (overall)
mem_used()

# check the change in memory due to each step

# DATA IMPORT ----------------
mem_change(flights <- read.csv(DATA_PATH))

# DATA PREPARATION --------
flights <- flights[,-1:-3]

# check how much memory is used by R now
mem_used()


## -------------------------------------------------------------------------------------------------
gc()


## -------------------------------------------------------------------------------------------------
# load packages
library(data.table)

# DATA IMPORT ----------------
flights <- fread(DATA_PATH, verbose = TRUE)



## -------------------------------------------------------------------------------------------------

# SET UP -----------------

# fix variables
DATA_PATH <- "materials/data/flights.csv"
# load packages
library(pryr) 
library(data.table)

# housekeeping
flights <- NULL
gc()

# check the change in memory due to each step

# DATA IMPORT ----------------
mem_change(flights <- fread(DATA_PATH))




## BEYOND MEMORY ------------------

# SET UP --------------

# install.packages(c("ff", "ffbase"))
# load packages
library(ff)
library(ffbase)
library(pryr)

# create directory for ff chunks, and assign directory to ff 
system("mkdir ffdf")
options(fftempdir = "ffdf")


gc()


# Import data, inspect change in RAM.
mem_change(
   flights <- 
      read.table.ffdf(file="materials/data/flights.csv",
                      sep=",",
                      VERBOSE=TRUE,
                      header=TRUE,
                      next.rows=100000,
                      colClasses=NA)
)


# Inspect file chunks on disk

# show the files in the directory keeping the chunks
list.files("ffdf")

# investigate the structure of the object created in the R environment
summary(flights)




# Memory mapping with the big memory package
# SET UP ----------------

# load packages
library(bigmemory)
library(biganalytics)



