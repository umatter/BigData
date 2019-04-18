## mkdir ~/.R

## ----eval=FALSE----------------------------------------------------------
## # CASE STUDY: PARALLEL ---------------------------
## 
## 
## # NOTE: the default EC2 AMI instance uses a newer compiler which data.table does not like,
## # before you can install data.table, switch to the terminal in your current RStudio Server session and
## # type the following:
## # mkdir ~/.R
## # echo "CC=gcc64" >> ~/.R/Makevars
## # this sets the default to an older C compiler.
## # See https://stackoverflow.com/questions/48576682/r-and-data-table-on-aws for details.
## 
## # install packages
## install.packages("data.table")
## install.packages("doSNOW")
## 
## # load packages
## library(data.table)
## 
## 
## ## ------------------------------------------------------------------------
## stopdata <- read.csv("https://vincentarelbundock.github.io/Rdatasets/csv/carData/MplsStops.csv")
## 
## ## ------------------------------------------------------------------------
## # remove incomplete obs
## stopdata <- na.omit(stopdata)
## # code dependent var
## stopdata$vsearch <- 0
## stopdata$vsearch[stopdata$vehicleSearch=="YES"] <- 1
## # code explanatory var
## stopdata$white <- 0
## stopdata$white[stopdata$race=="White"] <- 1
## 
## ## ------------------------------------------------------------------------
## model <- vsearch ~ white + factor(policePrecinct)
## 
## ## ------------------------------------------------------------------------
## fit <- lm(model, stopdata)
## summary(fit)
## 
## 
## # bootstrapping: normal approach
## 
## ## ----message=FALSE-------------------------------------------------------
## 
## # set the 'seed' for random numbers (makes the example reproducible)
## set.seed(2)
## 
## # set number of bootstrap iterations
## B <- 50
## # get selection of precincts
## precincts <- unique(stopdata$policePrecinct)
## # container for coefficients
## boot_coefs <- matrix(NA, nrow = B, ncol = 2)
## # draw bootstrap samples, estimate model for each sample
## for (i in 1:B) {
## 
##   # draw sample of precincts (cluster level)
##   precincts_i <- sample(precincts, size = 5, replace = TRUE)
##   # get observations
##   bs_i <- lapply(precincts_i, function(x) stopdata[stopdata$policePrecinct==x,])
##   bs_i <- rbindlist(bs_i)
## 
##   # estimate model and record coefficients
##   boot_coefs[i,] <- coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
## }
## 
## ## ------------------------------------------------------------------------
## se_boot <- apply(boot_coefs,
##                  MARGIN = 2,
##                  FUN = sd)
## se_boot
## 
## 
## 

## ----eval=FALSE----------------------------------------------------------
## parallel::detectCores()

## ----eval=FALSE----------------------------------------------------------
## 
## # bootstrapping: parallel approaach
## 
## ## ----message=FALSE-------------------------------------------------------
## # install.packages("doSNOW", "parallel")
## # load packages for parallel processing
## library(doSNOW)
## 
## # get the number of cores available
## ncores <- parallel::detectCores()
## # set cores for parallel processing
## ctemp <- makeCluster(ncores) #
## registerDoSNOW(ctemp)
## 
## 
## # set number of bootstrap iterations
## B <- 50
## # get selection of precincts
## precincts <- unique(stopdata$policePrecinct)
## # container for coefficients
## boot_coefs <- matrix(NA, nrow = B, ncol = 2)
## 
## # bootstrapping in parallel
## boot_coefs <-
##   foreach(i = 1:B, .combine = rbind, .packages="data.table") %dopar% {
## 
##     # draw sample of precincts (cluster level)
##     precincts_i <- sample(precincts, size = 5, replace = TRUE)
##     # get observations
##     bs_i <- lapply(precincts_i, function(x) stopdata[stopdata$policePrecinct==x,])
##     bs_i <- rbindlist(bs_i)
## 
##     # estimate model and record coefficients
##     coef(lm(model, bs_i))[1:2] # ignore FE-coefficients
## 
##   }
## 
## 
## # be a good citizen and stop the snow clusters
## stopCluster(cl = ctemp)
## 
## 
## 
## ## ------------------------------------------------------------------------
## se_boot <- apply(boot_coefs,
##                  MARGIN = 2,
##                  FUN = sd)
## se_boot
## 
## 
## 

## # from the directory where the key-file is stored...

## sudo apt-get install software-properties-common

## ----eval= FALSE---------------------------------------------------------
## # load packages
## library(RMySQL)
## 
## # connect to the db
## con <- dbConnect(RMySQL::MySQL(),
##                  user = "umatter",
##                  password = "Password1",
##                  host = "localhost",
##                  dbname = "data1")
## 

## ------------------------------------------------------------------------
input_text <-
"Simon is a friend of Becky.
Becky is a friend of Ann.
Ann is not a friend of Simon."

## ------------------------------------------------------------------------
# Mapper splits input into lines
lines <- as.list(strsplit(input_text, "\n")[[1]])
lines

## ------------------------------------------------------------------------

# Mapper splits lines into Key-Value pairs
map_fun <-
     function(x){
          
          # remove special characters
          x_clean <- gsub("[[:punct:]]", "", x)
          # split line into words
          keys <- unlist(strsplit(x_clean, " "))
          # initiate key-value pairs
          key_values <- rep(1, length(keys))
          names(key_values) <- keys
          
          return(key_values)
     }

kv_pairs <- Map(map_fun, lines)

# look at the result
kv_pairs

## ------------------------------------------------------------------------
# order and shuffle
kv_pairs <- unlist(kv_pairs)
keys <- unique(names(kv_pairs))
keys <- keys[order(keys)]
shuffled <- lapply(keys,
                    function(x) kv_pairs[x == names(kv_pairs)])
shuffled

## ------------------------------------------------------------------------
sums <- sapply(shuffled, sum)
names(sums) <- keys
sums

## ------------------------------------------------------------------------
# assigns the number of words per line as value
map_fun2 <- 
     function(x){
          # remove special characters
          x_clean <- gsub("[[:punct:]]", "", x)
          # split line into words, count no. of words per line
          values <- length(unlist(strsplit(x_clean, " ")))
          return(values)
     }
# Mapper
mapped <- Map(map_fun2, lines)
mapped

# Reducer
reduced <- Reduce(sum, mapped)
reduced

## ssh azureSandbox

## ssh root@localhost -p 2222

## useradd <username>

## ssh umatter@localhost -p 2222

## scp -P 2222 -r ~/Desktop/twain_data.txt umatter@localhost:~/data

##  scp -P 2222 -r ~/Desktop/wordcount umatter@localhost:~/wordcount

## scp -P 2222 -r umatter@localhost:~/wordcount/wordcount.txt ~/Desktop/wordcount_final.txt

