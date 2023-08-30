# initialize the input text (for simplicity as one text string)
input_text <-
"Apple Orange Mango
Orange Grapes Plum
Apple Plum Mango
Apple Apple Plum"


# Mapper splits input into lines
lines <- as.list(strsplit(input_text, "\n")[[1]])
lines[1:2]


# Mapper splits lines into key–value pairs
map_fun <-
     function(x){
          
          # remove special characters
          x_clean <- gsub("[[:punct:]]", "", x)
          # split line into words
          keys <- unlist(strsplit(x_clean, " "))
          # initialize key–value pairs
          key_values <- rep(1, length(keys))
          names(key_values) <- keys
          
          return(key_values)
     }

kv_pairs <- Map(map_fun, lines)

# look at the result
kv_pairs[1:2]

# order and shuffle
kv_pairs <- unlist(kv_pairs)
keys <- unique(names(kv_pairs))
keys <- keys[order(keys)]
shuffled <- lapply(keys,
                    function(x) kv_pairs[x == names(kv_pairs)])
shuffled[1:2]

sums <- lapply(shuffled, Reduce, f=sum)
names(sums) <- keys
sums[1:2]

# create directory for input files (typically text files)

mkdir ~/input


echo "Apple Orange Mango

Orange Grapes Plum

Apple Plum Mango

Apple Apple Plum" >>  ~/input/text.txt




# run mapreduce word count

/usr/local/hadoop/bin/hadoop jar \

/usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.10.1.jar \

wordcount

~/input ~/wc_example


cat ~/wc_example/*




# might have to switch to java version 8 first

sudo update-alternatives --config java




$ SPARK-HOME/bin/sparkR


# to install use
# devtools::install_github("cran/SparkR")
# load packages
library(SparkR)
# start session
sparkR.session()


# install.packages("SparkR")
# or, if temporarily not available on CRAN:
#if (!require('devtools')) install.packages('devtools')
#devtools::install_github('apache/spark@v2.x.x', subdir='R/pkg') # replace x.x with the version of your spark installation

# load packages
library(SparkR)

# start session
sparkR.session(sparkHome = "/home/umatter/.cache/spark/spark-3.1.2-bin-hadoop2.7")



# Import data and create a SparkDataFrame 
# (a distributed collection of data, RDD)
flights <- read.df("data/flights.csv", source = "csv", header="true")

# inspect the object
class(flights)
dim(flights)


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

# Convert result back into native R object
delays <- collect(long_flights_delays)
class(delays)
delays

cd SPARK-HOME




$ bin/spark-sql


{"name":"Michael", "salary":3000}

{"name":"Andy", "salary":4500}

{"name":"Justin", "salary":3500}

{"name":"Berta", "salary":4000}




SELECT *

FROM json.`examples/src/main/resources/employees.json`

;






SELECT *

FROM json.`examples/src/main/resources/employees.json`

WHERE salary <4000

;






SELECT AVG(salary) AS mean_salary

FROM json.`examples/src/main/resources/employees.json`;




# to install use
# devtools::install_github("cran/SparkR")
# load packages
library(SparkR)
# start session
sparkR.session()
# read data 
flights <- read.df("data/flights.csv", source = "csv", header="true")


# register the data frame as a table
createOrReplaceTempView(flights, "flights" )

# now run SQL queries on it
query <- 
"SELECT DISTINCT carrier,
year,
arr_delay,
distance
FROM flights
WHERE 1000 <= distance"

long_flights2 <- sql(query)
head(long_flights2)

