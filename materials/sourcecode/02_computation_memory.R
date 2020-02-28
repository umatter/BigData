## -------------------------------------------------------------------------------------------------
my_number <- 139
# check the class
typeof(my_number)

# arithmetic
my_number*2


## ----error=TRUE-----------------------------------------------------------------------------------
# change and check type/class
my_number_string <- as.character(my_number)
typeof(my_number_string)

# try to multiply
my_number_string*2


## -------------------------------------------------------------------------------------------------
# change and check type/class
my_number_int <- as.integer(my_number)
typeof(my_number_int)
# arithmetics
my_number_int*2


## -------------------------------------------------------------------------------------------------
object.size("139")
object.size(139)


## -------------------------------------------------------------------------------------------------
beta_ols <- 
     function(X, y) {
          
          # compute cross products and inverse
          XXi <- solve(crossprod(X,X))
          Xy <- crossprod(X, y) 
          
          return( XXi  %*% Xy )
     }


## -------------------------------------------------------------------------------------------------
# set parameter values
n <- 10000000
p <- 4 

# Generate sample based on Monte Carlo
# generate a design matrix (~ our 'dataset') with four variables and 10000 observations
X <- matrix(rnorm(n*p, mean = 10), ncol = p)
# add column for intercept
X <- cbind(rep(1, n), X)



## -------------------------------------------------------------------------------------------------
# MC model
y <- 2 + 1.5*X[,2] + 4*X[,3] - 3.5*X[,4] + 0.5*X[,5] + rnorm(n)



## -------------------------------------------------------------------------------------------------
# apply the ols estimator
beta_ols(X, y)


## -------------------------------------------------------------------------------------------------


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



## -------------------------------------------------------------------------------------------------
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


## -------------------------------------------------------------------------------------------------
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



## ----message=FALSE, warning=FALSE-----------------------------------------------------------------
# load packages
library(ggplot2)

# prepare data to plot
plotdata <- data.frame(beta1 = mc_results,
                       time_elapsed = mc_times,
                       subs_size = n_subs_sizes)


## -------------------------------------------------------------------------------------------------
ggplot(plotdata, aes(x = subs_size, y = time_elapsed)) +
     geom_point(color="darkgreen") + 
     geom_hline(yintercept = ols_time[3],
                color = "red", 
                size = 1) +
     theme_minimal() +
     ylab("Time elapsed") +
     xlab("Subsample size")


## -------------------------------------------------------------------------------------------------
ggplot(plotdata, aes(x = subs_size, y = beta1)) +
     geom_hline(yintercept = ols_res,
                color = "red", 
                size = 1) +
       geom_hline(yintercept = 1.5,
                color = "green",
                size = 1) +
     geom_point(color="darkgreen") + 

     theme_minimal() +
     ylab("Estimated coefficient") +
     xlab("Subsample size")

