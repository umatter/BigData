## sudo amazon-linux-extras install R3.4


## # April 2020

## wget https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.5033-x86_64.rpm

## sudo yum install rstudio-server-rhel-1.2.5033-x86_64.rpm


## ----eval=FALSE-----------------------------------------------------------------------------------
## # CASE STUDY: PARALLEL ---------------------------
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


## ----eval=FALSE-----------------------------------------------------------------------------------
## parallel::detectCores()


## ----eval=FALSE-----------------------------------------------------------------------------------
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


## # update ubuntu packages

##  sudo apt-get update

##  sudo apt-get upgrade


## sudo apt-get install r-base


## sudo apt-get install gdebi-core

## wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.2.5033-amd64.deb

## sudo gdebi rstudio-server-1.2.5033-amd64.deb


## # create user

## sudo adduser umatter


## sudo cp -r /home/ubuntu/.ssh /home/umatter/

## cd /home/umatter/

## sudo chown -R umatter:umatter .ssh


## sudo apt update

## sudo apt install mariadb-server

## sudo apt install libmariadbclient-dev

## sudo apt install libxml2-dev # needed later (dependency for some R packages)


## # from the directory where the key-file is stored...

## scp -r -i "mariadb_ec2.pem" ~/Desktop/economics.csv umatter@ec2-184-72-202-166.compute-1.amazonaws.com:~/


## # start the MariaDB server

## sudo service mysql start

## # log into the MariaDB client as root

## sudo mysql -uroot




## # start the MariaDB server

## sudo service mysql restart

## # log into the MariaDB client as root

## mysql -uroot -p










## ----eval= FALSE----------------------------------------------------------------------------------
## # install package
## #install.packages("RMySQL")
## # load packages
## library(RMySQL)
## 
## # connect to the db
## con <- dbConnect(RMySQL::MySQL(),
##                  user = "root",
##                  password = "Password1",
##                  host = "localhost",
##                  dbname = "data1")
## 






## -------------------------------------------------------------------------------------------------
input_text <-
"Simon is a friend of Becky.
Becky is a friend of Ann.
Ann is not a friend of Simon."


## -------------------------------------------------------------------------------------------------
# Mapper splits input into lines
lines <- as.list(strsplit(input_text, "\n")[[1]])
lines


## -------------------------------------------------------------------------------------------------

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


## -------------------------------------------------------------------------------------------------
# order and shuffle
kv_pairs <- unlist(kv_pairs)
keys <- unique(names(kv_pairs))
keys <- keys[order(keys)]
shuffled <- lapply(keys,
                    function(x) kv_pairs[x == names(kv_pairs)])
shuffled


## -------------------------------------------------------------------------------------------------
sums <- sapply(shuffled, sum)
names(sums) <- keys
sums


## -------------------------------------------------------------------------------------------------
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


## # download binary

## wget https://downloads.apache.org/hadoop/common/hadoop-2.10.0/hadoop-2.10.0.tar.gz

## # download checksum

## wget https://www.apache.org/dist/hadoop/common/hadoop-2.10.0/hadoop-2.10.0.tar.gz.sha512

## 
## # run the verification

## shasum -a 512 hadoop-2.10.0.tar.gz

## # compare with value in mds file

## cat hadoop-2.10.0.tar.gz.sha512

## 
## # if all is fine, unpack

## tar -xzvf hadoop-2.10.0.tar.gz

## # move to proper place

## sudo mv hadoop-2.10.0 /usr/local/hadoop

## 
## 
## # then point to this version from hadoop

## # open the file /usr/local/hadoop/etc/hadoop/hadoop-env.sh

## # in a text editor and add (where export JAVA_HOME=...)

## export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

## 
## # clean up

## rm hadoop-2.10.0.tar.gz

## rm hadoop-2.10.0.tar.gz.sha512


## # check installation

## /usr/local/hadoop/bin/hadoop


## # create directory for input files (typically text files)

## mkdir ~/input


## echo "Simon is a friend of Becky

## Becky is a friend of Ann

## Ann is not a friend of Simon" >>  ~/input/text.txt

## 

## # run mapreduce word count

## /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.10.0.jar wordcount ~/input ~/wc_example


## cat ~/wc_example/*

