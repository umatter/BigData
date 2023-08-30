# how much time does it take to run this loop?
system.time(for (i in 1:100) {i + 5})

# load package
library(microbenchmark)
# how much time does it take to run this loop (exactly)?
microbenchmark(for (i in 1:100) {i + 5})

hello <- "Hello, World!"
object.size(hello)

# initialize a large string vector containing letters
large_string <- rep(LETTERS[1:20], 1000^2)
head(large_string)

# store the same information as a factor in a new variable
large_factor <- as.factor(large_string)

# is one bigger than the other?
object.size(large_string) - object.size(large_factor)

# load package
library(pryr)

# initialize a vector with 1000 (pseudo)-random numbers
mem_change(
        thousand_numbers <- runif(1000)
        )



# initialize a vector with 1M (pseudo)-random numbers
mem_change(
        a_million_numbers <- runif(1000^2)
        )

# load packages
library(bench)

# initialize variables
x <- 1:10000
z <- 1.5

# approach I: loop
multiplication <- 
        function(x,z) {
                result <- c()
                for (i in 1:length(x)) {result <- c(result, x[i]*z)}
                return(result)
        }
result <- multiplication(x,z)
head(result)

# approach II: "R-style"
result2 <- x * z 
head(result2)

# comparison
benchmarking <- 
        mark(
        result <- multiplication(x,z),
        result2 <- x * z, 
        min_iterations = 50 
)
benchmarking[, 4:9]


plot(benchmarking, type = "boxplot")

# load package
library(profvis)

# analyze performance of several lines of code
profvis({
        x <- 1:10000
        z <- 1.5

# approach I: loop
multiplication <-
        function(x,z) {
                result <- c()
                for (i in 1:length(x)) {result <- c(result, x[i]*z)}
                return(result)
        }
result <- multiplication(x,z)

# approach II: "R-style"
result2 <- x * z
head(result2)
})

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


# the different sizes of the vectors we will put into the two functions
input_sizes <- seq(from = 100, to = 10000, by = 100)
# create the input vectors
inputs <- sapply(input_sizes, rnorm)

# compute outputs for each of the functions
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

# load packages
library(ggplot2)

# initialize data frame for plot
plotdata <- data.frame(time_elapsed = c(output_slower, output_faster),
                       input_size = c(input_sizes, input_sizes),
                       Implementation= c(rep("sqrt_vector",
                                             length(output_slower)),
                                         rep("sqrt_vector_faster",
                                             length(output_faster))))

# plot
ggplot(plotdata, aes(x=input_size, y= time_elapsed)) +
     geom_point(aes(colour=Implementation)) +
     theme_minimal(base_size = 18) +
     theme(legend.position = "bottom") +
     ylab("Time elapsed (in seconds)") +
     xlab("No. of elements processed") 
     

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

# load packages
library(ggplot2)

# initialize data frame for plot
plotdata <- data.frame(time_elapsed = c(output_faster, output_fastest),
                       input_size = c(input_sizes, input_sizes),
                       Implementation= c(rep("sqrt_vector_faster",
                                             length(output_faster)),
                                         rep("sqrt_vector_fastest",
                                             length(output_fastest))))

# plot
ggplot(plotdata, aes(x=time_elapsed, y=Implementation)) +
     geom_boxplot(aes(colour=Implementation),
                          show.legend = FALSE) +
     theme_minimal(base_size = 18) +
     xlab("Time elapsed (in seconds)")
     



# load packages
library(data.table)

# get a list of all file-paths
textfiles <- list.files("data/twitter_texts", full.names = TRUE)


# prepare loop
all_texts <- list()
n_files <- length(textfiles)
length(all_texts) <- n_files
# read all files listed in textfiles
for (i in 1:n_files) {
     all_texts[[i]] <- fread(textfiles[i])
}


# combine all in one data.table
twitter_text <- rbindlist(all_texts)
# check result
dim(twitter_text)


# use lapply instead of loop
all_texts <- lapply(textfiles, fread)
# combine all in one data.table
twitter_text <- rbindlist(all_texts)
# check result
dim(twitter_text)


# initialize the import function
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
dim(twitter_text)

a <- runif(10000)

b <- a

object_size(a)
mem_change(c <- a)

# load packages
library(lobstr)

# check memory addresses of objects
obj_addr(a)
obj_addr(b)

# check the first element's value
a[1]
b[1]

# modify a, check memory change
mem_change(a[1] <- 0)

# check memory addresses
obj_addr(a)
obj_addr(b)


mem_change(d <- runif(10000))
mem_change(d[1] <- 0)

mem_change(large_vector <- runif(10^8))
mem_change(rm(large_vector))

import_file

sum

# import data
econ <- read.csv("data/economics.csv")

# filter
econ2 <- econ["1968-01-01"<=econ$date,]

# compute yearly averages (basic R approach)
econ2$year <- lubridate::year(econ2$date)
years <- unique(econ2$year)
averages <- 
     sapply(years, FUN = function(x){
          mean(econ2[econ2$year==x,"unemploy"])
          })
output <- data.frame(year=years, average_unemploy=averages)

# inspect the first few lines of the result
head(output)




SELECT

strftime('%Y', `date`)  AS year,

AVG(unemploy) AS average_unemploy

FROM econ

WHERE "1968-01-01"<=`date`

GROUP BY year LIMIT 6;




groupby























select_example



simple_query





# import data
econ <- read.csv("data/economics.csv")
inflation <- read.csv("data/inflation.csv")

# prepare variable to match observations
econ$year <- lubridate::year(econ$date)
inflation$year <- lubridate::year(inflation$date)

# create final output
years <- unique(econ$year)
averages <- sapply(years, FUN = function(x) {
        mean(econ[econ$year==x,"unemploy"]/econ[econ$year==x,"pop"])*100
        
} )
unemp <- data.frame(year=years,
                     average_unemp_percent=averages)
# combine via the year column
# keep all rows of econ
output<- merge(unemp, inflation[, c("year", "inflation_percent")], by="year")
# inspect output
head(output)


SELECT

strftime('%Y', econ.date)  AS year,

AVG(unemploy/pop)*100 AS average_unemp_percent,

inflation_percent

FROM econ INNER JOIN inflation ON year = strftime('%Y', inflation.date)

GROUP BY year


innerjoin_example[1:6,]

dbDisconnect(con)

# replace "YOUR-API-KEY" with
# your actual key
Sys.setenv(OPENAI_API_KEY = "YOUR-API-KEY")
# open chat window
gptstudio:::chat_gpt_addin()

select date,

unemploy from econ

where unemploy > 15000

order by date;

