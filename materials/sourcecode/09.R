
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


