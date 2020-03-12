## echo "# bigdatastat" >> README.md

## git init

## git add README.md

## git commit -m "first commit"

## git remote add origin https://github.com/umatter/bigdatastat.git

## git push -u origin master


## git clone https://github.com/umatter/BigData.git


## cd BigData


## git pull


## -------------------------------------------------------------------------------------------------
a <- 1.5
b <- 3
a + b


## -------------------------------------------------------------------------------------------------
typeof(a)
class(a)
object.size(a)


## ----eval=FALSE-----------------------------------------------------------------------------------
## a <- "1.5"
## b <- "3"
## a + b


## -------------------------------------------------------------------------------------------------
typeof(a)
class(a)
object.size(a)




## -------------------------------------------------------------------------------------------------
hometown <- c("St.Gallen", "Basel", "St.Gallen")
hometown
object.size(hometown)




## -------------------------------------------------------------------------------------------------
hometown_f <- factor(c("St.Gallen", "Basel", "St.Gallen"))
hometown_f
object.size(hometown_f)


## -------------------------------------------------------------------------------------------------
# create a large character vector
hometown_large <- rep(hometown, times = 1000)
# and the same content as factor
hometown_large_f <- factor(hometown_large)
# compare size
object.size(hometown_large)
object.size(hometown_large_f)




## -------------------------------------------------------------------------------------------------
my_matrix <- matrix(c(1,2,3,4,5,6), nrow = 3)
my_matrix



## -------------------------------------------------------------------------------------------------
my_array <- array(c(1,2,3,4,5,6), dim = 3)
my_array





## -------------------------------------------------------------------------------------------------
# load package
library(data.table)
# initiate a data.table
dt <- data.table(person = c("Alice", "Ben"),
                 age = c(50, 30),
                 gender = c("f", "m"))
dt





## -------------------------------------------------------------------------------------------------
my_list <- list(my_array, my_matrix, dt)
my_list


## ----message=FALSE--------------------------------------------------------------------------------
# read a CSV-file the 'traditional way'
flights <- read.csv("../data/flights.csv")
class(flights)

# alternative (needs the data.table package)
library(data.table)
flights <- fread("../data/flights.csv")
class(flights)



## -------------------------------------------------------------------------------------------------
system.time(flights <- read.csv("../data/flights.csv"))
system.time(flights <- fread("../data/flights.csv"))


## -------------------------------------------------------------------------------------------------
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



## -------------------------------------------------------------------------------------------------
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


## -------------------------------------------------------------------------------------------------
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
     


## -------------------------------------------------------------------------------------------------
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


## -------------------------------------------------------------------------------------------------
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
     




## ----message=FALSE--------------------------------------------------------------------------------
# load packages
library(data.table)

# get a list of all file-paths
textfiles <- list.files("../data/twitter_texts", full.names = TRUE)



## ----message=FALSE, warning=FALSE-----------------------------------------------------------------
# prepare loop
all_texts <- list()
n_files <- length(textfiles)
length(all_texts) <- n_files
# read all files listed in textfiles
for (i in 1:n_files) {
     all_texts[[i]] <- fread(textfiles[i])
}



## -------------------------------------------------------------------------------------------------
# combine all in one data.table
twitter_text <- rbindlist(all_texts)
# check result
str(twitter_text)



## ----message=FALSE, warning=FALSE-----------------------------------------------------------------
# prepare loop
all_texts <- lapply(textfiles, fread)
# combine all in one data.table
twitter_text <- rbindlist(all_texts)
# check result
str(twitter_text)



## ----message=FALSE, warning=FALSE-----------------------------------------------------------------
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


## -------------------------------------------------------------------------------------------------
import_file


## -------------------------------------------------------------------------------------------------
sum

