## echo "# bigdatastat" >> README.md

## git clone https://github.com/umatter/BigData.git

## cd BigData

## git pull

## ------------------------------------------------------------------------
a <- 1.5
b <- 3

## ------------------------------------------------------------------------
typeof(a)
class(a)

## ------------------------------------------------------------------------
a + b

## ------------------------------------------------------------------------
a <- "1.5"
b <- "3"

## ------------------------------------------------------------------------
typeof(a)
class(a)

## ----error=TRUE----------------------------------------------------------
a + b

## ------------------------------------------------------------------------
persons <- c("Andy", "Brian", "Claire")
persons

## ------------------------------------------------------------------------
ages <- c(24, 50, 30)
ages

## ------------------------------------------------------------------------
gender <- factor(c("Male", "Male", "Female"))
gender

## ------------------------------------------------------------------------
my_matrix <- matrix(c(1,2,3,4,5,6), nrow = 3)
my_matrix


## ------------------------------------------------------------------------
my_array <- array(c(1,2,3,4,5,6), dim = 3)
my_array


## ------------------------------------------------------------------------
# load package
library(data.table)
# initiate a data.table
dt <- data.table(person = persons, age = ages, gender = gender)
dt


## ------------------------------------------------------------------------
my_list <- list(my_array, my_matrix, df)
my_list

## ----message=FALSE-------------------------------------------------------
# read a CSV-file the 'traditional way'
flights <- read.csv("../data/flights.csv")
class(flights)

# alternative (needs the data.table package)
library(data.table)
flights <- fread("../data/flights.csv")
class(flights)


## ------------------------------------------------------------------------
system.time(flights <- read.csv("../data/flights.csv"))
system.time(flights <- fread("../data/flights.csv"))

## ------------------------------------------------------------------------
# naïve implementation
sqrt_vector <- 
     function(x) {
          output <- c()
          for (i in 1:length(x)) {
               output <- c(output, x[i]^(1/2))
          }
          
          return(output)
     }

# implementation with pre-allocation of memory
sqrt_vector_faster <- 
     function(x) {
          output <- rep(NA, length(x))
          for (i in 1:length(x)) {
               output[i] <-  x[i]^(1/2)
          }
          
          return(output)
     }


## ------------------------------------------------------------------------
# the different sizes of the vectors we will put into the two functions
input_sizes <- seq(from = 100, to = 10000, by = 100)
# create the input vectors
inputs <- sapply(input_sizes, rnorm)

# compute ouputs for each of the functions
output_slower <- 
     sapply(inputs, 
            function(x){ system.time(sqrt_vector(x))["elapsed"]
                 }
            )
output_faster <- 
     sapply(inputs, 
            function(x){ system.time(sqrt_vector_faster(x))["elapsed"]
                 }
            )

## ------------------------------------------------------------------------
# load packages
library(ggplot2)

# initiate data frame for plot
plotdata <- data.frame(time_elapsed = c(output_slower, output_faster),
                       input_size = c(input_sizes, input_sizes),
                       Implementation= c(rep("sqrt_vector", length(output_slower)),
                            rep("sqrt_vector_faster", length(output_faster))))

# plot
ggplot(plotdata, aes(x=input_size, y= time_elapsed)) +
     geom_point(aes(colour=Implementation)) +
     theme_minimal(base_size = 18) +
     ylab("Time elapsed (in seconds)") +
     xlab("No. of elements processed")
     

## ------------------------------------------------------------------------
# implementation with vectorization
sqrt_vector_fastest <- 
     function(x) {
               output <-  x^(1/2)
          return(output)
     }

# speed test
output_fastest <- 
     sapply(inputs, 
            function(x){ system.time(sqrt_vector_fastest(x))["elapsed"]
                 }
            )

## ------------------------------------------------------------------------
# load packages
library(ggplot2)

# initiate data frame for plot
plotdata <- data.frame(time_elapsed = c(output_faster, output_fastest),
                       input_size = c(input_sizes, input_sizes),
                       Implementation= c(rep("sqrt_vector_faster", length(output_faster)),
                            rep("sqrt_vector_fastest", length(output_fastest))))

# plot
ggplot(plotdata, aes(x=input_size, y= time_elapsed)) +
     geom_point(aes(colour=Implementation)) +
     theme_minimal(base_size = 18) +
     ylab("Time elapsed (in seconds)") +
     xlab("No. of elements processed")
     

## ----message=FALSE-------------------------------------------------------
# load packages
library(data.table)

# get a list of all file-paths
textfiles <- list.files("../data/twitter_texts", full.names = TRUE)


## ----message=FALSE, warning=FALSE----------------------------------------
# prepare loop
all_texts <- list()
n_files <- length(textfiles)
length(all_texts) <- n_files
# read all files listed in textfiles
for (i in 1:n_files) {
     all_texts[[i]] <- fread(textfiles[i])
}


## ------------------------------------------------------------------------
# combine all in one data.table
twitter_text <- rbindlist(all_texts)
# check result
str(twitter_text)


## ----message=FALSE, warning=FALSE----------------------------------------
# prepare loop
all_texts <- lapply(textfiles, fread)
# combine all in one data.table
twitter_text <- rbindlist(all_texts)
# check result
str(twitter_text)


## ----message=FALSE, warning=FALSE----------------------------------------
# initiate the import function
import_file <- 
     function(x) {
          parsed_x <- fread(x)
          return(parsed_x)
     }

# 'vectorize' it
import_files <- Vectorize(import_file, SIMPLIFY = FALSE)

# Apply the vectorized function
all_texts <- import_files(textfiles)
twitter_text <- rbindlist(all_texts)
# check the result
str(twitter_text)

## ------------------------------------------------------------------------
import_file

## ------------------------------------------------------------------------
sum

## ------------------------------------------------------------------------
beta_ols <- 
     function(X, y) {
          
          # compute cross products and inverse
          XXi <- solve(crossprod(X,X))
          Xy <- crossprod(X, y) 
          
          return( XXi  %*% Xy )
     }

## ------------------------------------------------------------------------
# set parameter values
n <- 10000000
p <- 4 

# Generate sample based on Monte Carlo
# generate a design matrix (~ our 'dataset') with four variables and 10000 observations
X <- matrix(rnorm(n*p, mean = 10), ncol = p)
# add column for intercept
X <- cbind(rep(1, n), X)


## ------------------------------------------------------------------------
# MC model
y <- 2 + 1.5*X[,2] + 4*X[,3] - 3.5*X[,4] + 0.5*X[,5] + rnorm(n)


## ------------------------------------------------------------------------
# apply the ols estimator
beta_ols(X, y)

## ------------------------------------------------------------------------


beta_uluru <-
     function(X_subs, y_subs, X_rem, y_rem) {
          
          # compute beta_fs (this is simply OLS applied to the subsample)
          XXi_subs <- solve(crossprod(X_subs, X_subs))
          Xy_subs <- crossprod(X_subs, y_subs)
          b_fs <- XXi_subs  %*% Xy_subs
          
          # compute \mathbf{R}_{rem}
          R_rem <- y_rem - X_rem %*% b_fs
          
          # compute \hat{\beta}_{correct}
          b_correct <- (nrow(X_subs)/(nrow(X_rem))) * XXi_subs %*% crossprod(X_rem, R_rem)

          # beta uluru       
          return(b_fs + b_correct)
     }


## ------------------------------------------------------------------------
# set size of subsample
n_subs <- 1000
# select subsample and remainder
n_obs <- nrow(X)
X_subs <- X[1L:n_subs,]
y_subs <- y[1L:n_subs]
X_rem <- X[(n_subs+1L):n_obs,]
y_rem <- y[(n_subs+1L):n_obs]

# apply the uluru estimator
beta_uluru(X_subs, y_subs, X_rem, y_rem)

## ------------------------------------------------------------------------
# define subsamples
n_subs_sizes <- seq(from = 1000, to = 500000, by=10000)
n_runs <- length(n_subs_sizes)
# compute uluru result, stop time
mc_results <- rep(NA, n_runs)
mc_times <- rep(NA, n_runs)
for (i in 1:n_runs) {
     # set size of subsample
     n_subs <- n_subs_sizes[i]
     # select subsample and remainder
     n_obs <- nrow(X)
     X_subs <- X[1L:n_subs,]
     y_subs <- y[1L:n_subs]
     X_rem <- X[(n_subs+1L):n_obs,]
     y_rem <- y[(n_subs+1L):n_obs]
     
     mc_results[i] <- beta_uluru(X_subs, y_subs, X_rem, y_rem)[2] # the first element is the intercept
     mc_times[i] <- system.time(beta_uluru(X_subs, y_subs, X_rem, y_rem))[3]
     
}

# compute ols results and ols time
ols_time <- system.time(beta_ols(X, y))
ols_res <- beta_ols(X, y)[2]


## ------------------------------------------------------------------------
# load packages
library(ggplot2)

# prepare data to plot
plotdata <- data.frame(beta1 = mc_results,
                       time_elapsed = mc_times,
                       subs_size = n_subs_sizes)

## ------------------------------------------------------------------------
ggplot(plotdata, aes(x = subs_size, y = time_elapsed)) +
     geom_point(color="darkgreen") + 
     geom_hline(yintercept = ols_time[3],
                color = "red", 
                size = 1) +
     theme_minimal() +
     ylab("Time elapsed") +
     xlab("Subsample size")

## ------------------------------------------------------------------------
ggplot(plotdata, aes(x = subs_size, y = beta1)) +
     geom_hline(yintercept = ols_res,
                color = "red", 
                size = 1) +
     geom_point(color="darkgreen") + 

     theme_minimal() +
     ylab("Estimated coefficient") +
     xlab("Subsample size")

