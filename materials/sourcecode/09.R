
# --------------

# install.packages("SparkR")

# load packages
library(SparkR)

# start session
sparkR.session()



# SUMMARY STATS ----------------------

# Import data and create a SparkDataFrame (a distributed collection of data, RDD)
flights <- read.df(path="../data/flights.csv", source = "csv", header="true")

# inspect the object
str(flights)
head(flights)






# prepare data
flights$dep_delay <- cast(flights$dep_delay, "double")
flights$dep_time <- cast(flights$dep_time, "double")
flights$arr_time <- cast(flights$arr_time, "double")
flights$arr_delay <- cast(flights$arr_delay, "double")
flights$air_time <- cast(flights$air_time, "double")
flights$distance <- cast(flights$distance, "double")



# filter
long_flights <- select(flights, "carrier", "year", "arr_delay", "distance")
long_flights <- filter(long_flights, long_flights$distance >= 1000)
head(long_flights)




# aggregation: mean delay per carrier
long_flights_delays<- summarize(groupBy(long_flights, long_flights$carrier),
                                avg_delay = mean(long_flights$arr_delay))
head(long_flights_delays)






# 'EXPORT' -----------------------------

# Convert result back into native R object
delays <- collect(long_flights_delays)
class(delays)
delays



# R REGRESSION ------------------------


# flights_r <- collect(flights) # very slow!
flights_r <- data.table::fread("materials/data/flights.csv", nrows = 300) 

# specify the linear model
model1 <- arr_delay ~ dep_delay + distance
# fit the model with ols
fit1 <- lm(model1, flights_r)
# compute t-tests etc.
summary(fit1)





# SPARK REGRESSION ------------------------------ 

# create SparkDataFrame
flights2 <- createDataFrame(flights_r)
# fit the model
fit1_spark <- spark.glm(formula = model1, data = flights2 , family="gaussian")
# compute t-tests etc.
summary(fit1_spark)






# GPUs---------------------------




# SET UP --------------------------

# load package
library(bench)
library(gpuR)




# initiate dataset with pseudo random numbers
N <- 10000  # number of observations
P <- 100 # number of variables
X <- matrix(rnorm(N * P, 0, 1), nrow = N, ncol =P)


# PREPARE GPU COMPUTING ---------------------

# prepare GPU-specific objects/settings
gpuX <- gpuMatrix(X, type = "float")  # point GPU to matrix (matrix stored in non-GPU memory)
vclX <- vclMatrix(X, type = "float")  # transfer matrix to GPU (matrix stored in GPU memory)



# RUN CODE, BENCHMARK ------------------------


# compare three approaches
gpu_cpu <- bench::mark(
     
     # compute with CPU 
     cpu <- t(X) %*% X,
     
     # GPU version, GPU pointer to CPU memory (gpuMatrix is simply a pointer)
     gpu1_pointer <- t(gpuX) %*% gpuX,
     
     # GPU version, in GPU memory (vclMatrix formation is a memory transfer)
     gpu2_memory <- t(vclX) %*% vclX,
     
     check = FALSE, min_iterations = 20)



# VISUALIZE RESULTS ------------------------

plot(gpu_cpu, type = "boxplot")


