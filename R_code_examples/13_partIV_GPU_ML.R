set.seed(1)
# set parameter values
n <- 100000
p <- 4 
# generate a design matrix (~ our 'dataset') 
# with p variables and n observations
X <- matrix(rnorm(n*p, mean = 10), ncol = p)
# add column for intercept
#X <- cbind(rep(1, n), X)

# MC model
y <-  1.5*X[,1] + 4*X[,2] - 3.5*X[,3] + 0.5*X[,4] + rnorm(n)



beta_ols_gpu <- 
     function(X, y, gpu_memory=FALSE) {
          require(gpuR)
          
          if (!gpu_memory){
               # point GPU to matrix (matrix stored in non-GPU memory)
               vclX <- vclMatrix(X, type = "float")
               vcly <- vclVector(y, type = "float")
               # compute cross products and inverse
               XXi <- solve(crossprod(vclX,vclX))
               Xy <- crossprod(vclX, vcly) 
          } else {
               # point GPU to matrix (matrix stored in non-GPU memory)
               gpuX <- gpuMatrix(X, type = "float")
               gpuy <- gpuVector(y, type = "float")
               # compute cross products and inverse
               XXi <- solve(crossprod(gpuX,gpuX))
               Xy <- t(gpuX)  %*% gpuy
          }
          beta_hat <- as.vector(XXi  %*% Xy)
          return(beta_hat)
     }


beta_ols_gpu(X,y)

beta_ols_gpu(X,y, gpu_memory = TRUE)

if (Sys.info()["sysname"]=="Darwin"){ # run on macOS machine
     
        use_python("/Users/umatter/opt/anaconda3/bin/python") # IMPORTANT: keras/tensorflow is set up to run in this environment on this machine!
}


# load packages
library(keras)
library(tibble)
library(ggplot2)
library(tfdatasets)
# load data
boston_housing <- dataset_boston_housing()
str(boston_housing)

# assign training and test data/labels
c(train_data, train_labels) %<-% boston_housing$train
c(test_data, test_labels) %<-% boston_housing$test


library(dplyr)

column_names <- c('CRIM', 'ZN', 'INDUS', 'CHAS', 'NOX', 'RM', 'AGE', 
                  'DIS', 'RAD', 'TAX', 'PTRATIO', 'B', 'LSTAT')

train_df <- train_data %>% 
  as_tibble(.name_repair = "minimal") %>% 
  setNames(column_names) %>% 
  mutate(label = train_labels)

test_df <- test_data %>% 
  as_tibble(.name_repair = "minimal") %>% 
  setNames(column_names) %>% 
  mutate(label = test_labels)

# check training data dimensions and content
dim(train_df)
head(train_df) 

spec <- feature_spec(train_df, label ~ . ) %>%
  step_numeric_column(all_numeric(), normalizer_fn = scaler_standard()) %>%
  fit()

# Create the model
# model specification
input <- layer_input_from_dataset(train_df %>% select(-label))

output <- input %>% 
  layer_dense_features(dense_features(spec)) %>% 
  layer_dense(units = 64, activation = "relu") %>%
  layer_dense(units = 64, activation = "relu") %>%
  layer_dense(units = 1) 

model <- keras_model(input, output)


# compile the model  
model %>% 
  compile(
    loss = "mse",
    optimizer = optimizer_rmsprop(),
    metrics = list("mean_absolute_error")
  )

# get a summary of the model
model

# Set max. number of epochs
epochs <- 500

# Fit the model and store training stats
history <- model %>% fit(
  x = train_df %>% select(-label),
  y = train_df$label,
  epochs = epochs,
  validation_split = 0.2,
  verbose = 0
)
plot(history)
