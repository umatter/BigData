


# PROFILING -----------

# implement function
f <- function() {
     pause(0.1)
     g()
     h()
}
g <- function() {
     pause(0.1)
     h()
}
h <- function() {
     pause(0.1)
}



# load package with profiler
library(profvis)
# get performance profile of function
profvis(f())