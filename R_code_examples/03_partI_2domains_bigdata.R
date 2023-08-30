# import/inspect data
ga <- read.csv("data/ga.csv")
head(ga[, c("source", "browser", "city", "purchase")])
# create model matrix (dummy vars)
mm <- cbind(ga$purchase,
            model.matrix(purchase~source, data=ga,)[,-1])
mm_df <- as.data.frame(mm)
# clean variable names
names(mm_df) <- c("purchase",
                  gsub("source", "", names(mm_df)[-1]))
# run logit
model1 <- glm(purchase ~ .,
              data=mm_df, family=binomial)

model1_sum <- summary(model1)
# select "significant" variables for final model
pvalues <- model1_sum$coefficients[,"Pr(>|z|)"]
vars <- names(pvalues[which(pvalues<0.05)][-1])
vars

# specify and estimate the final model
finalmodel <- glm(purchase ~.,
                  data = mm_df[, c("purchase", vars)],
                  family = binomial)

summary(finalmodel)$coef[,c("Estimate", "Pr(>|z|)")]

# load packages
library(gamlr)
# create the model matrix
mm <- model.matrix(purchase~source, data = ga)

# create the sparse model matrix
mm_sparse <- sparse.model.matrix(purchase~source, data = ga)
# compare the object's sizes
as.numeric(object.size(mm)/object.size(mm_sparse))

# run k-fold cross-validation lasso
cvpurchase <- cv.gamlr(mm_sparse, ga$purchase, family="binomial")

# load packages
library(PRROC)
# use "best" model for prediction
# (model selection based on average OSS deviance
pred <- predict(cvpurchase$gamlr, mm_sparse, type="response")
# compute tpr, fpr; plot ROC
comparison <- roc.curve(scores.class0 = pred,
                       weights.class0=ga$purchase,
                       curve=TRUE)
plot(comparison)

beta_ols <-
     function(X, y) {
          # compute cross products and inverse
          XXi <- solve(crossprod(X,X))
          Xy <- crossprod(X, y)
          return( XXi  %*% Xy )
     }

# set parameter values
n <- 10000000
p <- 4
# generate sample based on Monte Carlo
# generate a design matrix (~ our 'dataset')
# with 4 variables and 10,000 observations
X <- matrix(rnorm(n*p, mean = 10), ncol = p)
# add column for intercept
X <- cbind(rep(1, n), X)

# MC model
y <- 2 + 1.5*X[,2] + 4*X[,3] - 3.5*X[,4] + 0.5*X[,5] + rnorm(n)

# apply the OLS estimator
beta_ols(X, y)

beta_uluru <-
     function(X_subs, y_subs, X_rem, y_rem) {
          # compute beta_fs
          #(this is simply OLS applied to the subsample)
          XXi_subs <- solve(crossprod(X_subs, X_subs))
          Xy_subs <- crossprod(X_subs, y_subs)
          b_fs <- XXi_subs  %*% Xy_subs
          # compute \mathbf{R}_{rem}
          R_rem <- y_rem - X_rem %*% b_fs
          # compute \hat{\beta}_{correct}
          b_correct <-
               (nrow(X_subs)/(nrow(X_rem))) *
               XXi_subs %*% crossprod(X_rem, R_rem)
          # beta uluru
          return(b_fs + b_correct)
     }

# set size of sub-sample
n_subs <- 1000
# select sub-sample and remainder
n_obs <- nrow(X)
X_subs <- X[1L:n_subs,]
y_subs <- y[1L:n_subs]
X_rem <- X[(n_subs+1L):n_obs,]
y_rem <- y[(n_subs+1L):n_obs]
# apply the uluru estimator
beta_uluru(X_subs, y_subs, X_rem, y_rem)

# define sub-samples
n_subs_sizes <- seq(from = 1000, to = 500000, by=10000)
n_runs <- length(n_subs_sizes)
# compute uluru result, stop time
mc_results <- rep(NA, n_runs)
mc_times <- rep(NA, n_runs)
for (i in 1:n_runs) {
     # set size of sub-sample
     n_subs <- n_subs_sizes[i]
     # select sub-sample and remainder
     n_obs <- nrow(X)
     X_subs <- X[1L:n_subs,]
     y_subs <- y[1L:n_subs]
     X_rem <- X[(n_subs+1L):n_obs,]
     y_rem <- y[(n_subs+1L):n_obs]
     mc_results[i] <- beta_uluru(X_subs,
                                 y_subs,
                                 X_rem,
                                 y_rem)[2] # (1 is the intercept)
     mc_times[i] <- system.time(beta_uluru(X_subs,
                                           y_subs,
                                           X_rem,
                                           y_rem))[3]
}
# compute OLS results and OLS time
ols_time <- system.time(beta_ols(X, y))
ols_res <- beta_ols(X, y)[2]

# load packages
library(ggplot2)
# prepare data to plot
plotdata <- data.frame(beta1 = mc_results,
                       time_elapsed = mc_times,
                       subs_size = n_subs_sizes)

ggplot(plotdata, aes(x = subs_size, y = time_elapsed)) +
     geom_point(color="darkgreen") +
     geom_hline(yintercept = ols_time[3],
                color = "red",
                linewidth = 1) +
     theme_minimal() +
     ylab("Time elapsed") +
     xlab("Subsample size")



ggplot(plotdata, aes(x = subs_size, y = beta1)) +
     geom_hline(yintercept = ols_res,
                color = "red",
                linewidth = 1) +
       geom_hline(yintercept = 1.5,
                color = "green",
                linewidth = 1) +
     geom_point(color="darkgreen") +
     theme_minimal() +
     ylab("Estimated coefficient") +
     xlab("Subsample size")
