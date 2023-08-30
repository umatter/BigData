# flights_r <- collect(flights) # very slow!
flights_r <- data.table::fread("data/flights.csv", nrows = 300) 

# specify the linear model
model1 <- arr_delay ~ dep_delay + distance
# fit the model with OLS
fit1 <- lm(model1, flights_r)
# compute t-tests etc.
summary(fit1)

library(sparklyr)

# connect with default configuration
sc <- spark_connect(master="local")


# load data to spark
flights_spark <- copy_to(sc, flights_r, "flights_spark")
# fit the model
fit1_spark <- ml_linear_regression(flights_spark, formula = model1)
# compute summary stats
summary(fit1_spark)


# fit the model
spark_apply(flights_spark,
            function(df){
              broom::tidy(lm(arr_delay ~ dep_delay + distance, df))},
            names = c("term",
                      "estimate",
                      "std.error",
                      "statistic",
                      "p.value")
    )

library(tidymodels)
library(parsnip)

# simple local linear regression example from above
# via tidymodels/parsnip
fit1 <- fit(linear_reg(engine="lm"), model1, data=flights_r)
tidy(fit1)



# run the same on Spark
fit1_spark <- fit(linear_reg(engine="spark"), model1, data=flights_spark)
tidy(fit1_spark)

# load into R, select variables of interest, remove missing
titanic_r <- read.csv("data/titanic3.csv")
titanic_r <- na.omit(titanic_r[, c("survived",
                           "pclass",
                           "sex",
                           "age",
                           "sibsp",
                           "parch")])
titanic_r$survived <- ifelse(titanic_r$survived==1, "yes", "no")

library(rsample)

# split into training and test set
titanic_r <- initial_split(titanic_r)
ti_training <- training(titanic_r)
ti_testing <- testing(titanic_r)

# load data to spark
ti_training_spark <- copy_to(sc, ti_training, "ti_training_spark")
ti_testing_spark <- copy_to(sc, ti_testing, "ti_testing_spark")

# models to be used
models <- list(logit=logistic_reg(engine="spark", mode = "classification"),
               btree=boost_tree(engine = "spark", mode = "classification"),
               rforest=rand_forest(engine = "spark", mode = "classification"))
# train/fit the models
fits <- lapply(models, fit, formula=survived~., data=ti_training_spark)


# run predictions
predictions <- lapply(fits, predict, new_data=ti_testing_spark)
# fetch predictions from Spark, format, add actual outcomes
pred_outcomes <-
     lapply(1:length(predictions), function(i){
          x_r <- collect(predictions[[i]]) # load into local R environment
          x_r$pred_class <- as.factor(x_r$pred_class) # format for predictions
          x_r$survived <- as.factor(ti_testing$survived) # add true outcomes
          return(x_r)

})


acc <- lapply(pred_outcomes, accuracy, truth="survived", estimate="pred_class")
acc <- bind_rows(acc)
acc$model <- names(fits)
acc[order(acc$.estimate, decreasing = TRUE),]

tidy(fits[["btree"]])

tidy(fits[["rforest"]])

spark_disconnect(sc)

# load packages
library(sparklyr)
library(dplyr)

# fix vars
INPUT_DATA <- "data/ga.csv"


# import to local R session, prepare raw data
ga <- na.omit(read.csv(INPUT_DATA))
#ga$purchase <- as.factor(ifelse(ga$purchase==1, "yes", "no"))
# connect to, and copy the data to the local cluster
sc <- spark_connect(master = "local")
ga_spark <- copy_to(sc, ga, "ga_spark", overwrite = TRUE)


# ml pipeline
ga_pipeline <-
     ml_pipeline(sc) %>%
     ft_string_indexer(input_col="city",
                       output_col="city_output",
                       handle_invalid = "skip") %>%
     ft_string_indexer(input_col="country",
                       output_col="country_output",
                       handle_invalid = "skip") %>%
     ft_string_indexer(input_col="source",
                       output_col="source_output",
                       handle_invalid = "skip") %>%
     ft_string_indexer(input_col="browser",
                       output_col="browser_output",
                       handle_invalid = "skip") %>%
     ft_r_formula(purchase ~ .) %>%
     ml_logistic_regression(elastic_net_param = list(alpha=1))


# specify the hyperparameter grid
# (parameter values to be considered in optimization)
ga_params <- list(logistic_regression=list(max_iter=80))

# create the cross-validator object
set.seed(1)
cv_lasso <- ml_cross_validator(sc,
                         estimator=ga_pipeline,
                         estimator_param_maps = ga_params,
                         ml_binary_classification_evaluator(sc),
                         num_folds = 30,
                         parallelism = 8)

# train/fit the model
cv_lasso_fit <- ml_fit(cv_lasso, ga_spark)
# note: this takes several minutes to run on a local machine (1 node, 8 cores)


# pipeline summary
# cv_lasso_fit
# average performance
cv_lasso_fit$avg_metrics_df


# save the entire pipeline/fit
ml_save(
  cv_lasso_fit,
  "ga_cv_lasso_fit",
  overwrite = TRUE
)


